-- Consultas CRUD parametrizadas equivalentes a las usadas por el monolito antes de encapsular lógica.
-- psql usa \set sólo para demostrar parámetros; la aplicación usa $1, $2, etc. mediante pg.
SELECT b.id,b.isbn,b.title,b.price,b.stock,f.name format,c.name category,string_agg(DISTINCT a.name,', ') authors
FROM books b JOIN formats f ON f.id=b.format_id JOIN categories c ON c.id=b.category_id
LEFT JOIN book_authors ba ON ba.book_id=b.id LEFT JOIN authors a ON a.id=ba.author_id
WHERE b.title ILIKE '%sintético%' OR b.isbn ILIKE '%978%' GROUP BY b.id,f.name,c.name ORDER BY b.title;

SELECT b.*,f.name format,c.name category FROM books b JOIN formats f ON f.id=b.format_id JOIN categories c ON c.id=b.category_id WHERE b.id=1;
SELECT a.* FROM authors a JOIN book_authors ba ON ba.author_id=a.id WHERE ba.book_id=1;
SELECT g.* FROM genres g JOIN book_genres bg ON bg.genre_id=g.id WHERE bg.book_id=1;
SELECT c.term,bc.definition FROM concepts c JOIN book_concepts bc ON bc.concept_id=c.id WHERE bc.book_id=1;
SELECT * FROM book_images WHERE book_id=1 ORDER BY is_primary DESC,sort_order;

BEGIN;
INSERT INTO books(isbn,title,publication_year,price,stock,format_id,category_id,description) VALUES('9781234567897','Libro temporal',2026,199.00,10,1,1,'Alta CRUD temporal');
UPDATE books SET price=209.00,stock=11,updated_at=now() WHERE isbn='9781234567897';
DELETE FROM books WHERE isbn='9781234567897';
ROLLBACK;

-- Integridad: ejecutar fuera de transacciones de carga. Debe fallar con duplicate key
-- value violates unique constraint "ux_users_single_admin".
-- INSERT INTO users(name,email,password_hash,role) VALUES('Segundo Admin','admin2@example.test',crypt('Password123!',gen_salt('bf',12)),'admin');

SELECT conrelid::regclass tabla,conname,t.contype FROM pg_constraint t WHERE connamespace='public'::regnamespace ORDER BY tabla::text,conname;
SELECT tablename,indexname,indexdef FROM pg_indexes WHERE schemaname='public' ORDER BY tablename,indexname;
