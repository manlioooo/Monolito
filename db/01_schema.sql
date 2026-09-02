BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TYPE user_role AS ENUM ('user','admin');

CREATE TABLE users (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 name varchar(120) NOT NULL CHECK (length(trim(name))>=2),
 email varchar(254) NOT NULL,
 password_hash varchar(100) NOT NULL CHECK (length(password_hash)>=20),
 role user_role NOT NULL DEFAULT 'user', active boolean NOT NULL DEFAULT true,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT uq_users_email UNIQUE(email), CONSTRAINT ck_users_email CHECK(email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$')
);
-- Un índice único parcial permite cualquier número de usuarios y como máximo un administrador.
CREATE UNIQUE INDEX ux_users_single_admin ON users ((role)) WHERE role='admin';

-- Tabla técnica de express-session; no forma parte del modelo de negocio.
-- json contiene estado interno del servidor, no se intercambia con el navegador.
CREATE TABLE user_sessions (
 sid varchar NOT NULL PRIMARY KEY,
 sess json NOT NULL,
 expire timestamp(6) NOT NULL
);
CREATE INDEX ix_user_sessions_expire ON user_sessions(expire);

CREATE TABLE formats (id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,name varchar(80) NOT NULL UNIQUE,description text NOT NULL DEFAULT '');
CREATE TABLE categories (id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,name varchar(100) NOT NULL UNIQUE,description text NOT NULL DEFAULT '');
CREATE TABLE authors (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,name varchar(180) NOT NULL UNIQUE,biography text NOT NULL DEFAULT '');
CREATE TABLE genres (id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,name varchar(100) NOT NULL UNIQUE,description text NOT NULL DEFAULT '');
CREATE TABLE concepts (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,term varchar(160) NOT NULL UNIQUE);

CREATE TABLE books (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, isbn varchar(17) NOT NULL UNIQUE,
 title varchar(250) NOT NULL CHECK(length(trim(title))>0), publication_year smallint NOT NULL CHECK(publication_year BETWEEN 1450 AND 2100),
 price numeric(12,2) NOT NULL CHECK(price>=0), stock integer NOT NULL DEFAULT 0 CHECK(stock>=0),
 format_id smallint NOT NULL REFERENCES formats(id) ON UPDATE CASCADE ON DELETE RESTRICT,
 category_id smallint NOT NULL REFERENCES categories(id) ON UPDATE CASCADE ON DELETE RESTRICT,
 description text, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT ck_books_isbn CHECK(isbn ~ '^(97[89][- ]?)?[0-9][- 0-9]{8,14}[0-9X]$')
);
CREATE INDEX ix_books_title ON books(title); CREATE INDEX ix_books_format ON books(format_id); CREATE INDEX ix_books_category ON books(category_id);

CREATE TABLE book_authors (book_id bigint NOT NULL REFERENCES books(id) ON DELETE CASCADE,author_id bigint NOT NULL REFERENCES authors(id) ON DELETE RESTRICT,author_order smallint NOT NULL DEFAULT 1 CHECK(author_order>0),PRIMARY KEY(book_id,author_id));
CREATE INDEX ix_book_authors_author ON book_authors(author_id);
CREATE TABLE book_genres (book_id bigint NOT NULL REFERENCES books(id) ON DELETE CASCADE,genre_id smallint NOT NULL REFERENCES genres(id) ON DELETE RESTRICT,PRIMARY KEY(book_id,genre_id));
CREATE INDEX ix_book_genres_genre ON book_genres(genre_id);
CREATE TABLE book_concepts (book_id bigint NOT NULL REFERENCES books(id) ON DELETE CASCADE,concept_id bigint NOT NULL REFERENCES concepts(id) ON DELETE RESTRICT,definition text NOT NULL CHECK(length(trim(definition))>=10),chapter_reference varchar(80),page_reference varchar(40),PRIMARY KEY(book_id,concept_id));
CREATE INDEX ix_book_concepts_concept ON book_concepts(concept_id);
CREATE TABLE book_images (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,book_id bigint NOT NULL REFERENCES books(id) ON DELETE CASCADE,file_path varchar(500) NOT NULL UNIQUE,alt_text varchar(250) NOT NULL DEFAULT '',sort_order smallint NOT NULL DEFAULT 0 CHECK(sort_order>=0),is_primary boolean NOT NULL DEFAULT false,created_at timestamptz NOT NULL DEFAULT now());
CREATE INDEX ix_book_images_book ON book_images(book_id);
CREATE UNIQUE INDEX ux_book_images_one_primary ON book_images(book_id) WHERE is_primary;
COMMIT;
