\echo '=== Restricciones PK, FK, UNIQUE y CHECK ==='
SELECT conrelid::regclass tabla,conname,CASE contype WHEN 'p' THEN 'PRIMARY KEY' WHEN 'f' THEN 'FOREIGN KEY' WHEN 'u' THEN 'UNIQUE' WHEN 'c' THEN 'CHECK' END tipo,pg_get_constraintdef(oid) definicion FROM pg_constraint WHERE connamespace='public'::regnamespace ORDER BY 1,2;
\echo '=== Índices ==='
SELECT tablename,indexname,indexdef FROM pg_indexes WHERE schemaname='public' ORDER BY 1,2;
\echo '=== Conteos esperados (30 antes de usar la aplicación) ==='
SELECT 'users' tabla,count(*) FROM users UNION ALL SELECT 'books',count(*) FROM books UNION ALL SELECT 'authors',count(*) FROM authors UNION ALL SELECT 'book_images',count(*) FROM book_images;

DO $$ BEGIN
 BEGIN INSERT INTO users(name,email,password_hash,role) VALUES('Segundo Administrador','second-admin@example.test',crypt('Password123!',gen_salt('bf',12)),'admin');
 EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'CORRECTO segundo admin rechazado [%]: %',SQLSTATE,SQLERRM; END;
 BEGIN INSERT INTO books(isbn,title,publication_year,price,stock,format_id,category_id) SELECT isbn,'Duplicado',2026,10,1,format_id,category_id FROM books LIMIT 1;
 EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'CORRECTO ISBN duplicado rechazado [%]: %',SQLSTATE,SQLERRM; END;
 BEGIN UPDATE books SET price=-1 WHERE id=(SELECT min(id) FROM books);
 EXCEPTION WHEN check_violation THEN RAISE NOTICE 'CORRECTO precio negativo rechazado [%]: %',SQLSTATE,SQLERRM; END;
 BEGIN UPDATE books SET stock=-1 WHERE id=(SELECT min(id) FROM books);
 EXCEPTION WHEN check_violation THEN RAISE NOTICE 'CORRECTO stock negativo rechazado [%]: %',SQLSTATE,SQLERRM; END;
 BEGIN INSERT INTO book_genres(book_id,genre_id) VALUES(999999,1);
 EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'CORRECTO FK inválida rechazada [%]: %',SQLSTATE,SQLERRM; END;
 BEGIN DELETE FROM formats WHERE id=(SELECT format_id FROM books LIMIT 1);
 EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'CORRECTO eliminación RESTRICT rechazada [%]: %',SQLSTATE,SQLERRM; END;
END $$;
