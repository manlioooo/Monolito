"""Catálogo monolítico: una app Flask, PostgreSQL y respuestas XML."""
import os
import re
from decimal import Decimal, InvalidOperation
from xml.etree import ElementTree as ET

import psycopg
from psycopg.rows import dict_row
from flask import Flask, Response, request, redirect, url_for
from werkzeug.exceptions import HTTPException, BadRequest, NotFound

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 1024 * 1024


def connect():
    # El contexto confirma la transacción o la revierte si ocurre un error.
    return psycopg.connect(os.environ.get('DATABASE_URL', ''),
                           row_factory=dict_row, connect_timeout=5)


def xml_response(root, status=200, stylesheet=False):
    data = b'<?xml version="1.0" encoding="UTF-8"?>\n'
    if stylesheet:
        data += b'<?xml-stylesheet type="text/css" href="/static/catalog.css"?>\n'
    data += ET.tostring(root, encoding='utf-8')
    return Response(data, status=status, content_type='application/xml; charset=utf-8')


def element(parent, tag, value, **attrs):
    node = ET.SubElement(parent, tag, {k: str(v) for k, v in attrs.items()})
    node.text = '' if value is None else str(value)
    return node


def book_xml(conn, row):
    book = ET.Element('book', isbn=row['isbn'])
    element(book, 'title', row['title'])
    for author in conn.execute('''SELECT a.id, a.name FROM authors a
            JOIN book_authors ba ON ba.author_id=a.id WHERE ba.book_id=%s
            ORDER BY ba.author_order, a.id''', (row['id'],)):
        element(book, 'author', author['name'], id=author['id'])
    element(book, 'year', row['publication_year'])
    for genre in conn.execute('''SELECT g.id, g.name FROM genres g
            JOIN book_genres bg ON bg.genre_id=g.id WHERE bg.book_id=%s
            ORDER BY g.id''', (row['id'],)):
        element(book, 'genre', genre['name'], id=genre['id'])
    element(book, 'price', format(row['price'], '.2f'))
    element(book, 'stock', row['stock'])
    element(book, 'format', row['format_name'], id=row['format_id'])
    element(book, 'category', row['category_name'], id=row['category_id'])
    element(book, 'description', row['description'])
    images = ET.SubElement(book, 'images')
    for img in conn.execute('SELECT * FROM book_images WHERE book_id=%s ORDER BY sort_order,id', (row['id'],)):
        element(images, 'image', img['file_path'], alt=img['alt_text'],
                primary=str(img['is_primary']).lower())
    concepts = ET.SubElement(book, 'concepts')
    for item in conn.execute('''SELECT c.id,c.term,bc.definition,bc.chapter_reference,bc.page_reference
            FROM concepts c JOIN book_concepts bc ON bc.concept_id=c.id
            WHERE bc.book_id=%s ORDER BY c.id''', (row['id'],)):
        concept = ET.SubElement(concepts, 'concept', id=str(item['id']))
        element(concept, 'term', item['term'])
        element(concept, 'description', item['definition'])
        element(concept, 'chapter_reference', item['chapter_reference'])
        element(concept, 'page_reference', item['page_reference'])
    return book


SELECT_BOOKS = '''SELECT b.*, f.name AS format_name, c.name AS category_name
    FROM books b JOIN formats f ON f.id=b.format_id
    JOIN categories c ON c.id=b.category_id'''


def read_catalog(where='', params=(), single=False, status=200):
    with connect() as conn:
        conn.execute('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY')
        rows = conn.execute(SELECT_BOOKS + where + ' ORDER BY b.id', params).fetchall()
        if single:
            if not rows:
                raise NotFound('Libro no encontrado.')
            return xml_response(book_xml(conn, rows[0]), status, stylesheet=True)
        library = ET.Element('library')
        books = ET.SubElement(library, 'books')
        for row in rows:
            books.append(book_xml(conn, row))
        return xml_response(library, stylesheet=True)


@app.get('/')
def index():
    return redirect(url_for('books'))


@app.get('/api/books')
def books():
    return read_catalog()


@app.get('/api/book/<isbn>')
def book(isbn):
    return read_catalog(' WHERE b.isbn=%s', (isbn,), single=True)


@app.get('/api/book/author/<int:author_id>')
def by_author(author_id):
    return read_catalog(''' WHERE EXISTS (SELECT 1 FROM book_authors ba
        WHERE ba.book_id=b.id AND ba.author_id=%s)''', (author_id,))


SCALARS = ('title', 'publication_year', 'price', 'stock', 'format_id', 'category_id', 'description')
RELATIONS = ('author_ids', 'genre_ids', 'images', 'concepts')


def integer(value, field, low=1, high=9223372036854775807):
    if type(value) is not int or not low <= value <= high:
        raise BadRequest(f'{field}: se requiere un entero entre {low} y {high}.')
    return value


def string(value, field, minimum=0, maximum=None):
    if not isinstance(value, str) or len(value.strip()) < minimum or (maximum and len(value) > maximum):
        raise BadRequest(f'{field}: texto inválido.')
    # XML 1.0 no permite estos caracteres de control.
    if any(ord(c) < 32 and c not in '\t\n\r' or 0xD800 <= ord(c) <= 0xDFFF or ord(c) in (0xFFFE, 0xFFFF) for c in value):
        raise BadRequest(f'{field}: caracteres no permitidos en XML.')
    return value


def payload(insert=False, delete=False):
    data = request.get_json()
    if not isinstance(data, dict):
        raise BadRequest('Se requiere un objeto JSON.')
    allowed = {'isbn'} if delete else {'isbn', *SCALARS, *RELATIONS}
    if set(data) - allowed:
        raise BadRequest('Hay campos desconocidos.')
    isbn = string(data.get('isbn'), 'isbn', 1, 17)
    if not re.fullmatch(r'(97[89][- ]?)?[0-9][- 0-9]{8,14}[0-9X]', isbn):
        raise BadRequest('ISBN incompatible con 01_schema.sql.')
    if insert:
        required = {'title', 'publication_year', 'price', 'format_id', 'category_id', 'author_ids', 'genre_ids'}
        if required - data.keys():
            raise BadRequest('Faltan campos: ' + ', '.join(sorted(required - data.keys())))
        data.setdefault('stock', 0)
    if not insert and not delete and len(data) == 1:
        raise BadRequest('Incluye al menos un campo para actualizar.')
    for key in ('title', 'description'):
        if key in data and not (key == 'description' and data[key] is None):
            string(data[key], key, 1 if key == 'title' else 0, 250 if key == 'title' else None)
    for key, low, high in [('publication_year',1450,2100), ('stock',0,2147483647),
                           ('format_id',1,32767), ('category_id',1,32767)]:
        if key in data:
            integer(data[key], key, low, high)
    if 'price' in data:
        try:
            price = Decimal(str(data['price']))
            if not price.is_finite() or price < 0 or price > Decimal('9999999999.99') or price != price.quantize(Decimal('.01')):
                raise InvalidOperation
            data['price'] = price
        except (InvalidOperation, ValueError):
            raise BadRequest('price: importe no negativo con máximo dos decimales.')
    for key in RELATIONS:
        if key in data and not isinstance(data[key], list):
            raise BadRequest(f'{key}: se requiere una lista.')
    for key in ('author_ids', 'genre_ids'):
        if key in data:
            if not data[key]:
                raise BadRequest(f'{key}: incluye al menos un identificador.')
            for value in data[key]:
                integer(value, key, high=32767 if key == 'genre_ids' else 9223372036854775807)
            if len(set(data[key])) != len(data[key]) or len(data[key]) > 32767:
                raise BadRequest(f'{key}: identificadores repetidos o demasiados elementos.')
    for img in data.get('images', []):
        if not isinstance(img, dict) or set(img) - {'file_path', 'alt_text', 'sort_order', 'is_primary'}:
            raise BadRequest('Imagen inválida.')
        string(img.get('file_path'), 'file_path', 1, 500)
        string(img.get('alt_text', ''), 'alt_text', 0, 250)
        integer(img.get('sort_order', 0), 'sort_order', 0, 32767)
        if type(img.get('is_primary', False)) is not bool:
            raise BadRequest('is_primary debe ser booleano.')
    if sum(img.get('is_primary', False) for img in data.get('images', [])) > 1:
        raise BadRequest('Solo puede haber una imagen principal.')
    concept_ids = []
    for item in data.get('concepts', []):
        if not isinstance(item, dict) or set(item) - {'concept_id', 'definition', 'chapter_reference', 'page_reference'}:
            raise BadRequest('Concepto inválido.')
        concept_ids.append(integer(item.get('concept_id'), 'concept_id'))
        string(item.get('definition'), 'definition', 10)
        for field, length in [('chapter_reference',80), ('page_reference',40)]:
            if item.get(field) is not None:
                string(item[field], field, 0, length)
    if len(set(concept_ids)) != len(concept_ids):
        raise BadRequest('Conceptos repetidos.')
    return data


def replace_relations(conn, book_id, data):
    # Nombres SQL constantes; todos los valores externos son parámetros.
    for key, table, column in [('author_ids','book_authors','author_id'), ('genre_ids','book_genres','genre_id')]:
        if key in data:
            conn.execute(f'DELETE FROM {table} WHERE book_id=%s', (book_id,))
            for order, related_id in enumerate(data[key], 1):
                if key == 'author_ids':
                    conn.execute('INSERT INTO book_authors(book_id,author_id,author_order) VALUES (%s,%s,%s)', (book_id,related_id,order))
                else:
                    conn.execute(f'INSERT INTO {table}(book_id,{column}) VALUES (%s,%s)', (book_id,related_id))
    if 'images' in data:
        conn.execute('DELETE FROM book_images WHERE book_id=%s', (book_id,))
        for img in data['images']:
            conn.execute('''INSERT INTO book_images(book_id,file_path,alt_text,sort_order,is_primary)
                VALUES (%s,%s,%s,%s,%s)''', (book_id,img['file_path'],img.get('alt_text',''),img.get('sort_order',0),img.get('is_primary',False)))
    if 'concepts' in data:
        conn.execute('DELETE FROM book_concepts WHERE book_id=%s', (book_id,))
        for item in data['concepts']:
            conn.execute('''INSERT INTO book_concepts(book_id,concept_id,definition,chapter_reference,page_reference)
                VALUES (%s,%s,%s,%s,%s)''', (book_id,item['concept_id'],item['definition'],item.get('chapter_reference'),item.get('page_reference')))


@app.post('/api/book/insert')
def insert():
    data = payload(insert=True)
    with connect() as conn:
        fields = ['isbn'] + [key for key in SCALARS if key in data]
        row = conn.execute(f"INSERT INTO books ({','.join(fields)}) VALUES ({','.join(['%s'] * len(fields))}) RETURNING id",
                           [data[key] for key in fields]).fetchone()
        replace_relations(conn, row['id'], data)
        result = book_xml(conn, conn.execute(SELECT_BOOKS + ' WHERE b.id=%s', (row['id'],)).fetchone())
    response = xml_response(result, 201, stylesheet=True)
    response.headers['Location'] = url_for('book', isbn=data['isbn'])
    return response


@app.route('/api/book/update', methods=['PUT', 'PATCH'])
def update():
    data = payload()
    with connect() as conn:
        row = conn.execute('SELECT id FROM books WHERE isbn=%s FOR UPDATE', (data['isbn'],)).fetchone()
        if not row:
            raise NotFound('Libro no encontrado.')
        fields = [key for key in SCALARS if key in data]
        assignments = [f'{key}=%s' for key in fields] + ['updated_at=now()']
        conn.execute('UPDATE books SET ' + ','.join(assignments) + ' WHERE id=%s',
                     [data[key] for key in fields] + [row['id']])
        replace_relations(conn, row['id'], data)
        result = book_xml(conn, conn.execute(SELECT_BOOKS + ' WHERE b.id=%s', (row['id'],)).fetchone())
    return xml_response(result, stylesheet=True)


@app.delete('/api/book/delete')
def delete():
    data = payload(delete=True)
    with connect() as conn:
        if not conn.execute('DELETE FROM books WHERE isbn=%s RETURNING id', (data['isbn'],)).fetchone():
            raise NotFound('Libro no encontrado.')
    return xml_response(ET.Element('deleted', isbn=data['isbn']))


@app.errorhandler(HTTPException)
def http_error(error):
    root = ET.Element('error', status=str(error.code))
    element(root, 'message', error.description)
    response = xml_response(root, error.code)
    if error.code == 405:
        response.headers['Allow'] = ', '.join(error.valid_methods)
    return response


@app.errorhandler(psycopg.Error)
def database_error(error):
    if isinstance(error, psycopg.errors.UniqueViolation):
        status, message = 409, 'ISBN, imagen o relación ya existente.'
    elif isinstance(error, (psycopg.IntegrityError, psycopg.DataError)):
        status, message = 400, 'Datos incompatibles con el esquema o identificadores relacionados inexistentes.'
    elif isinstance(error, psycopg.OperationalError):
        status, message = 503, 'PostgreSQL no está disponible. Revisa DATABASE_URL.'
    else:
        app.logger.exception('Error de PostgreSQL')
        status, message = 500, 'Error interno de base de datos.'
    root = ET.Element('error', status=str(status))
    element(root, 'message', message)
    return xml_response(root, status)


if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000)
