'use strict';
const db = require('../config/db');

const masters = {
  formats: { table: 'formats', fields: ['name', 'description'], labels: ['Nombre', 'Descripción'] },
  categories: { table: 'categories', fields: ['name', 'description'], labels: ['Nombre', 'Descripción'] },
  authors: { table: 'authors', fields: ['name', 'biography'], labels: ['Nombre', 'Biografía'] },
  genres: { table: 'genres', fields: ['name', 'description'], labels: ['Nombre', 'Descripción'] },
  concepts: { table: 'concepts', fields: ['term'], labels: ['Término'] }
};

function resource(name) {
  const value = masters[name];
  if (!value) { const error = new Error('Recurso administrativo desconocido.'); error.status = 404; throw error; }
  return value;
}
function invalid(message){const error=new Error(message);error.status=400;throw error;}

async function listMaster(name) { const r=resource(name); return (await db.query(`SELECT * FROM ${r.table} ORDER BY id`)).rows; }
async function getMaster(name, id) { const r=resource(name); return (await db.query(`SELECT * FROM ${r.table} WHERE id=$1`, [id])).rows[0]; }
async function createMaster(name, body) {
  const r=resource(name), values=r.fields.map(f => String(body[f] || '').trim());
  if(!values[0]) invalid(`${r.labels[0]} es obligatorio.`);
  return (await db.query(`INSERT INTO ${r.table} (${r.fields.join(',')}) VALUES (${values.map((_,i)=>`$${i+1}`).join(',')}) RETURNING *`, values)).rows[0];
}
async function updateMaster(name, id, body) {
  const r=resource(name), values=r.fields.map(f => String(body[f] || '').trim());
  if(!values[0]) invalid(`${r.labels[0]} es obligatorio.`);
  return (await db.query(`UPDATE ${r.table} SET ${r.fields.map((f,i)=>`${f}=$${i+1}`).join(',')} WHERE id=$${values.length+1} RETURNING *`, [...values,id])).rows[0];
}
async function deleteMaster(name, id) { const r=resource(name); return db.query(`DELETE FROM ${r.table} WHERE id=$1`, [id]); }

async function options() {
  const [formats,categories,authors,genres,concepts] = await Promise.all(Object.keys(masters).map(listMaster));
  return { formats,categories,authors,genres,concepts };
}

async function saveBook(id, body) {
  const year=Number(body.publication_year),price=Number(body.price),stock=Number(body.stock),formatId=Number(body.format_id),categoryId=Number(body.category_id);
  if(!/^(97[89][- ]?)?[0-9][- 0-9]{8,14}[0-9X]$/.test(String(body.isbn||'').trim())) invalid('El ISBN no tiene un formato válido.');
  if(!String(body.title||'').trim()) invalid('El título es obligatorio.');
  if(!Number.isInteger(year)||year<1450||year>2100) invalid('El año debe estar entre 1450 y 2100.');
  if(!Number.isFinite(price)||price<0) invalid('El precio debe ser un número no negativo.');
  if(!Number.isInteger(stock)||stock<0) invalid('El stock debe ser un entero no negativo.');
  if(!Number.isInteger(formatId)||!Number.isInteger(categoryId)) invalid('Selecciona formato y categoría válidos.');
  const values=[body.isbn.trim(),body.title.trim(),year,price,stock,formatId,categoryId,body.description?.trim() || null];
  return db.transaction(async client => {
    let bookId=id;
    if (id) await client.query('UPDATE books SET isbn=$1,title=$2,publication_year=$3,price=$4,stock=$5,format_id=$6,category_id=$7,description=$8,updated_at=now() WHERE id=$9', [...values,id]);
    else bookId=(await client.query('INSERT INTO books(isbn,title,publication_year,price,stock,format_id,category_id,description) VALUES($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id', values)).rows[0].id;
    await client.query('DELETE FROM book_authors WHERE book_id=$1',[bookId]);
    await client.query('DELETE FROM book_genres WHERE book_id=$1',[bookId]);
    for (const authorId of [].concat(body.author_ids || []).filter(Boolean)) await client.query('INSERT INTO book_authors(book_id,author_id) VALUES($1,$2)',[bookId,authorId]);
    for (const genreId of [].concat(body.genre_ids || []).filter(Boolean)) await client.query('INSERT INTO book_genres(book_id,genre_id) VALUES($1,$2)',[bookId,genreId]);
    return bookId;
  });
}

module.exports={ masters,resource,listMaster,getMaster,createMaster,updateMaster,deleteMaster,options,saveBook };
