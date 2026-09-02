'use strict';
const db = require('../config/db');

async function listBooks(search = '') {
  const term = `%${search.trim()}%`;
  const { rows } = await db.query(`
    SELECT b.id, b.isbn, b.title, b.publication_year, b.price, b.stock,
           f.name AS format, c.name AS category,
           COALESCE(string_agg(DISTINCT a.name, ', '), '') AS authors,
           (SELECT bi.file_path FROM book_images bi WHERE bi.book_id=b.id ORDER BY bi.is_primary DESC, bi.sort_order, bi.id LIMIT 1) AS cover
    FROM books b
    JOIN formats f ON f.id=b.format_id JOIN categories c ON c.id=b.category_id
    LEFT JOIN book_authors ba ON ba.book_id=b.id LEFT JOIN authors a ON a.id=ba.author_id
    WHERE ($1 = '%%' OR b.title ILIKE $1 OR b.isbn ILIKE $1)
    GROUP BY b.id, f.name, c.name ORDER BY b.title`, [term]);
  return rows;
}

async function getBook(id) {
  const { rows } = await db.query(`
    SELECT b.*, f.name AS format, c.name AS category
    FROM books b JOIN formats f ON f.id=b.format_id JOIN categories c ON c.id=b.category_id
    WHERE b.id=$1`, [id]);
  if (!rows[0]) return null;
  const [authors, genres, concepts, images] = await Promise.all([
    db.query('SELECT a.* FROM authors a JOIN book_authors ba ON ba.author_id=a.id WHERE ba.book_id=$1 ORDER BY a.name', [id]),
    db.query('SELECT g.* FROM genres g JOIN book_genres bg ON bg.genre_id=g.id WHERE bg.book_id=$1 ORDER BY g.name', [id]),
    db.query('SELECT c.id, c.term, bc.definition,bc.chapter_reference,bc.page_reference FROM concepts c JOIN book_concepts bc ON bc.concept_id=c.id WHERE bc.book_id=$1 ORDER BY c.term', [id]),
    db.query('SELECT * FROM book_images WHERE book_id=$1 ORDER BY is_primary DESC, sort_order, id', [id])
  ]);
  return { ...rows[0], authors: authors.rows, genres: genres.rows, concepts: concepts.rows, images: images.rows };
}

module.exports = { listBooks, getBook };
