BEGIN;
CREATE OR REPLACE VIEW v_book_catalog AS SELECT b.id,b.isbn,b.title,b.publication_year,b.price,b.stock,f.name format,c.name category,COALESCE(string_agg(DISTINCT a.name,', '),'') authors FROM books b JOIN formats f ON f.id=b.format_id JOIN categories c ON c.id=b.category_id LEFT JOIN book_authors ba ON ba.book_id=b.id LEFT JOIN authors a ON a.id=ba.author_id GROUP BY b.id,f.name,c.name;
CREATE OR REPLACE VIEW v_book_concepts AS SELECT b.id book_id,b.title,c.id concept_id,c.term,bc.definition,bc.chapter_reference,bc.page_reference FROM book_concepts bc JOIN books b ON b.id=bc.book_id JOIN concepts c ON c.id=bc.concept_id;
CREATE OR REPLACE VIEW v_inventory_summary AS SELECT c.name category,count(b.id) titles,COALESCE(sum(b.stock),0) units,COALESCE(sum(b.stock*b.price),0) inventory_value FROM categories c LEFT JOIN books b ON b.category_id=c.id GROUP BY c.id;
COMMIT;
