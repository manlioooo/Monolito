-- Ejecutar una sola vez como administrador: psql -U postgres -f db/00_create_database.sql
-- CREATE DATABASE no puede ejecutarse dentro de una transacción.
-- postgres sólo realiza este bootstrap y no vuelve a utilizarse en el proyecto.
\prompt 'Contraseña nueva para el usuario propietario library_app: ' app_password
SELECT format('CREATE ROLE library_app LOGIN PASSWORD %L NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION', :'app_password')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname='library_app')\gexec
SELECT format('ALTER ROLE library_app WITH LOGIN PASSWORD %L NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION', :'app_password')\gexec
SELECT 'CREATE DATABASE online_library OWNER library_app ENCODING ''UTF8'' TEMPLATE template0'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'online_library')\gexec
\connect online_library
SET client_encoding='UTF8';
ALTER DATABASE online_library OWNER TO library_app;
REVOKE ALL ON DATABASE online_library FROM PUBLIC;
GRANT CONNECT,CREATE,TEMPORARY ON DATABASE online_library TO library_app;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
ALTER SCHEMA public OWNER TO library_app;
