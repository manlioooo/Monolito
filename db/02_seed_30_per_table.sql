-- 30 registros por cada tabla del diseño. Contraseña de todos: Password123!
BEGIN;
INSERT INTO formats(name,description) SELECT 'Formato '||g,'Formato editorial sintético número '||g FROM generate_series(1,30) g;
INSERT INTO categories(name,description) SELECT 'Categoría '||g,'Categoría comercial sintética número '||g FROM generate_series(1,30) g;
INSERT INTO authors(name,biography) SELECT 'Autor '||lpad(g::text,2,'0'),'Biografía sintética del autor '||g FROM generate_series(1,30) g;
INSERT INTO genres(name,description) SELECT 'Género '||lpad(g::text,2,'0'),'Descripción sintética del género '||g FROM generate_series(1,30) g;
INSERT INTO concepts(term) VALUES
('IaaS'),('PaaS'),('SaaS'),('FaaS'),('Bucket'),('Public Cloud'),('Private Cloud'),('Hybrid Cloud'),('Multicloud'),('Serverless'),
('Virtualización'),('Contenedor'),('Orquestación'),('Elasticidad'),('Escalabilidad'),('Alta disponibilidad'),('Balanceo de carga'),('Región'),('Zona de disponibilidad'),('Edge Computing'),('CDN'),('Base de datos administrada'),('Identidad y acceso'),('Cifrado'),('Observabilidad'),('DevOps'),('Infraestructura como código'),('Recuperación ante desastres'),('Responsabilidad compartida'),('FinOps');
INSERT INTO users(name,email,password_hash,role)
SELECT 'Usuario '||lpad(g::text,2,'0'),'usuario'||g||'@example.test',crypt('Password123!',gen_salt('bf',12)),CASE WHEN g=1 THEN 'admin'::user_role ELSE 'user'::user_role END FROM generate_series(1,30) g;
INSERT INTO books(isbn,title,publication_year,price,stock,format_id,category_id,description)
SELECT '978000000'||lpad(g::text,4,'0'),CASE WHEN g=1 THEN 'Fundamentos de Cloud Computing' ELSE 'Libro sintético '||lpad(g::text,2,'0') END,1990+g,99.00+g,g*2,g,g,CASE WHEN g=1 THEN 'Introducción práctica a modelos de servicio, despliegue y operación de sistemas en la nube.' ELSE 'Descripción editorial sintética del libro número '||g END FROM generate_series(1,30) g;
INSERT INTO book_authors(book_id,author_id,author_order) SELECT g,g,1 FROM generate_series(1,30) g;
INSERT INTO book_genres(book_id,genre_id) SELECT g,g FROM generate_series(1,30) g;
INSERT INTO book_concepts(book_id,concept_id,definition,chapter_reference,page_reference)
SELECT 1,g,CASE g WHEN 1 THEN 'Infraestructura virtualizada ofrecida bajo demanda como servicio.' WHEN 2 THEN 'Plataforma administrada para desarrollar y desplegar aplicaciones.' WHEN 3 THEN 'Software completo consumido por Internet mediante suscripción.' WHEN 4 THEN 'Ejecución de funciones por evento sin administrar servidores.' WHEN 5 THEN 'Contenedor lógico de almacenamiento de objetos en la nube.' WHEN 6 THEN 'Nube ofrecida por un proveedor a múltiples clientes.' WHEN 7 THEN 'Infraestructura de nube dedicada a una sola organización.' WHEN 8 THEN 'Integración coordinada de nube privada y nube pública.' WHEN 9 THEN 'Uso planificado de servicios de más de un proveedor de nube.' ELSE 'Modelo operativo donde el proveedor administra la infraestructura subyacente.' END,'Capítulo '||CASE WHEN g<=4 THEN 2 WHEN g<=6 THEN 3 ELSE 4 END,(20+g*3)::text FROM generate_series(1,10) g;
INSERT INTO book_concepts(book_id,concept_id,definition,chapter_reference,page_reference)
SELECT g-9,g,'Definición contextual de '||(SELECT term FROM concepts WHERE id=g)||' dentro del libro '||(g-9)||'.','Capítulo '||((g%8)+1),((g*7)+10)::text FROM generate_series(11,30) g;
INSERT INTO book_images(book_id,file_path,alt_text,sort_order,is_primary) SELECT g,'/seed/book-'||g||'.jpg','Portada sintética del libro '||g,0,true FROM generate_series(1,30) g;
COMMIT;

-- Verificación: cada resultado debe ser 30.
SELECT 'users' tabla,count(*) FROM users UNION ALL SELECT 'formats',count(*) FROM formats UNION ALL SELECT 'categories',count(*) FROM categories UNION ALL SELECT 'authors',count(*) FROM authors UNION ALL SELECT 'genres',count(*) FROM genres UNION ALL SELECT 'concepts',count(*) FROM concepts UNION ALL SELECT 'books',count(*) FROM books UNION ALL SELECT 'book_authors',count(*) FROM book_authors UNION ALL SELECT 'book_genres',count(*) FROM book_genres UNION ALL SELECT 'book_concepts',count(*) FROM book_concepts UNION ALL SELECT 'book_images',count(*) FROM book_images ORDER BY tabla;
