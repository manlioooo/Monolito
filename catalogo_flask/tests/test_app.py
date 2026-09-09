import unittest
from decimal import Decimal
from unittest.mock import MagicMock, patch
from xml.etree import ElementTree as ET

import psycopg
from app import app, book_xml


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_xml_contains_relations_and_escapes_text(self):
        conn = MagicMock()
        conn.execute.side_effect = [
            [{'id': 1, 'name': 'Ana & Luis'}, {'id': 2, 'name': 'Eva'}],
            [{'id': 1, 'name': 'Ciencia'}],
            [{'file_path': '/a.jpg', 'alt_text': 'Portada', 'is_primary': True}],
            [{'id': 3, 'term': 'Web', 'definition': 'Definición <del libro>',
              'chapter_reference': '1', 'page_reference': '9'}],
        ]
        row = dict(id=1, isbn='9781234567897', title='A < B', publication_year=2026,
                   price=Decimal('12.50'), stock=4, format_name='Papel', format_id=1,
                   category_name='Estudio', category_id=1, description=None)
        xml = ET.tostring(book_xml(conn, row))
        root = ET.fromstring(xml)
        self.assertEqual(root.attrib, {'isbn': row['isbn']})
        self.assertEqual(root.findtext('title'), 'A < B')
        self.assertEqual(len(root.findall('author')), 2)
        self.assertEqual(root.findtext('price'), '12.50')
        self.assertEqual(root.findtext('images/image'), '/a.jpg')
        self.assertEqual(root.findtext('concepts/concept/description'), 'Definición <del libro>')

    @patch('app.connect')
    def test_empty_catalog_and_stylesheet(self, connect):
        connect.return_value.__enter__.return_value.execute.return_value.fetchall.return_value = []
        response = self.client.get('/api/books')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.mimetype, 'application/xml')
        self.assertIn(b'xml-stylesheet', response.data)
        self.assertIsNotNone(ET.fromstring(response.data).find('books'))

    @patch('app.connect')
    def test_missing_book(self, connect):
        connect.return_value.__enter__.return_value.execute.return_value.fetchall.return_value = []
        self.assertEqual(self.client.get('/api/book/9781234567897').status_code, 404)

    @patch('app.connect')
    def test_author_filter_is_parameterized(self, connect):
        conn = connect.return_value.__enter__.return_value
        conn.execute.return_value.fetchall.return_value = []
        self.assertEqual(self.client.get('/api/book/author/7').status_code, 200)
        self.assertEqual(conn.execute.call_args.args[1], (7,))

    @patch('app.connect')
    def test_invalid_updates_never_connect(self, connect):
        for values in [{'stock': -1}, {'price': 'NaN'}, {'price': '1.001'},
                       {'genre_ids': []}, {'author_ids': [True]}, {'unknown': 1},
                       {'title': '\u0000'}, {'concepts': [{'concept_id': 1, 'definition': 'short'}]}]:
            with self.subTest(values=values):
                response = self.client.patch('/api/book/update', json={'isbn': '9781234567897', **values})
                self.assertEqual(response.status_code, 400)
        connect.assert_not_called()

    def test_method_and_content_type(self):
        self.assertEqual(self.client.post('/api/book/update', json={}).status_code, 405)
        self.assertEqual(self.client.post('/api/book/insert', data='no JSON').status_code, 415)
        self.assertEqual(self.client.post('/api/book/insert', json=[]).status_code, 400)

    @patch('app.connect', side_effect=psycopg.OperationalError('secret connection details'))
    def test_database_unavailable_is_sanitized(self, connect):
        response = self.client.get('/api/books')
        self.assertEqual(response.status_code, 503)
        self.assertNotIn(b'secret', response.data)

    @patch('app.connect')
    def test_delete(self, connect):
        conn = connect.return_value.__enter__.return_value
        conn.execute.return_value.fetchone.return_value = {'id': 1}
        response = self.client.delete('/api/book/delete', json={'isbn': '9781234567897'})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(ET.fromstring(response.data).tag, 'deleted')
        self.assertEqual(conn.execute.call_args.args[1], ('9781234567897',))

    @patch('app.book_xml', return_value=ET.Element('book', isbn='9781234567897'))
    @patch('app.connect')
    def test_insert_success(self, connect, serialize):
        conn = connect.return_value.__enter__.return_value
        conn.execute.return_value.fetchone.return_value = {'id': 42}
        response = self.client.post('/api/book/insert', json={
            'isbn': '9781234567897', 'title': 'Libro', 'publication_year': 2026,
            'price': '20.50', 'format_id': 1, 'category_id': 1,
            'author_ids': [1, 2], 'genre_ids': [1]})
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.headers['Location'], '/api/book/9781234567897')
        calls = conn.execute.call_args_list
        author_calls = [call for call in calls if 'INSERT INTO book_authors' in call.args[0]]
        self.assertEqual([call.args[1] for call in author_calls], [(42, 1, 1), (42, 2, 2)])
        self.assertIsNone(connect.return_value.__exit__.call_args.args[0])

    @patch('app.book_xml', return_value=ET.Element('book', isbn='9781234567897'))
    @patch('app.connect')
    def test_partial_update_preserves_omitted_relations(self, connect, serialize):
        conn = connect.return_value.__enter__.return_value
        conn.execute.return_value.fetchone.return_value = {'id': 42}
        response = self.client.patch('/api/book/update', json={'isbn': '9781234567897', 'stock': 20})
        self.assertEqual(response.status_code, 200)
        queries = [call.args[0] for call in conn.execute.call_args_list]
        self.assertTrue(any('FOR UPDATE' in query for query in queries))
        self.assertFalse(any('DELETE FROM' in query for query in queries))

    @patch('app.connect')
    def test_failed_relation_exits_transaction_with_error(self, connect):
        conn = connect.return_value.__enter__.return_value
        first = MagicMock()
        first.fetchone.return_value = {'id': 42}
        conn.execute.side_effect = [first, MagicMock(), psycopg.errors.ForeignKeyViolation('private detail')]
        response = self.client.patch('/api/book/update', json={
            'isbn': '9781234567897', 'author_ids': [999]})
        self.assertEqual(response.status_code, 400)
        self.assertIs(connect.return_value.__exit__.call_args.args[0], psycopg.errors.ForeignKeyViolation)
        self.assertNotIn(b'private detail', response.data)


if __name__ == '__main__':
    unittest.main()
