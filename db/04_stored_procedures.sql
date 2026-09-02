BEGIN;
CREATE OR REPLACE FUNCTION search_books(p_term text DEFAULT '') RETURNS TABLE(id bigint,isbn varchar,title varchar,authors text,price numeric,stock integer) LANGUAGE sql STABLE AS $$
 SELECT b.id,b.isbn,b.title,COALESCE(string_agg(DISTINCT a.name,', '),'') authors,b.price,b.stock FROM books b
 LEFT JOIN book_authors ba ON ba.book_id=b.id LEFT JOIN authors a ON a.id=ba.author_id
 WHERE b.title ILIKE '%'||p_term||'%' OR b.isbn ILIKE '%'||p_term||'%' GROUP BY b.id ORDER BY b.title
$$;
CREATE OR REPLACE PROCEDURE adjust_stock(p_book_id bigint,p_delta integer) LANGUAGE plpgsql AS $$
BEGIN
 UPDATE books SET stock=stock+p_delta,updated_at=now() WHERE id=p_book_id AND stock+p_delta>=0;
 IF NOT FOUND THEN RAISE EXCEPTION 'Libro inexistente o stock resultante negativo'; END IF;
END $$;
CREATE OR REPLACE PROCEDURE set_book_concept(p_book_id bigint,p_concept_id bigint,p_definition text,p_chapter varchar DEFAULT NULL,p_page varchar DEFAULT NULL) LANGUAGE sql AS $$
 INSERT INTO book_concepts(book_id,concept_id,definition,chapter_reference,page_reference) VALUES(p_book_id,p_concept_id,p_definition,p_chapter,p_page)
 ON CONFLICT(book_id,concept_id) DO UPDATE SET definition=excluded.definition,chapter_reference=excluded.chapter_reference,page_reference=excluded.page_reference
$$;
COMMIT;
