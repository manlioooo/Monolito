# Guía completa: GitHub → VM → PostgreSQL → Flask → evidencias

Referencia principal: CentOS Stream 10, según la documentación de este repositorio. También se incluyen comandos para Ubuntu 24.04. PostgreSQL es el motor de base de datos, no el sistema operativo. Ejecuta `cat /etc/os-release` en la VM para identificarlo. Esta guía instala la aplicación y PostgreSQL en la misma VM, usando una base nueva `catalogo_flask` y un rol nuevo `catalogo_user`, sin reutilizar la base del proyecto Node.js.

Los bloques PowerShell se ejecutan en tu PC Windows; los bloques bash, en la VM; el bloque SQL, dentro de psql. Sustituye `USUARIO_VM`, `IP_VM` y, si corresponde, el puerto SSH por tus datos. No escribas literalmente esos marcadores.

## 1. Subir los archivos desde Windows

El repositorio local ya tiene `origin = https://github.com/manlioooo/Monolito.git` y rama `main`. No necesitas crear otro repositorio ni ejecutar `git init`.

Abre PowerShell:

```powershell
Set-Location 'C:\Users\manil\OneDrive\Documents\ChatGPT\Integracion de Apps'
git status
git remote -v
git branch --show-current
git add catalogo_flask/
git diff --cached --stat
git diff --cached --name-only
```

Revisa que aparezcan el código, CSS, pruebas, ejemplos y esta guía. No deben aparecer `.venv`, `.env` ni contraseñas. Si ya había otros archivos preparados para commit, revísalos antes de continuar. El SQL `db/01_schema.sql` y el seed ya forman parte del proyecto; no se modifican.

```powershell
git commit -m "Agregar catalogo Flask PostgreSQL y guia para VM"
git push origin main
```

Si Git pide identidad, configura tu nombre y correo reales en este repositorio y repite el commit:

```powershell
git config user.name 'TU NOMBRE'
git config user.email 'TU CORREO DE GITHUB'
```

Si solicita autenticación, usa el inicio de sesión del administrador de credenciales de Git. GitHub no acepta la contraseña de tu cuenta como contraseña para Git sobre HTTPS; si tu configuración solicita un token, introdúcelo en el prompt, no en la URL. Si el push indica `rejected` por cambios remotos, ejecuta `git pull --rebase origin main`; si aparecen conflictos, resuélvelos antes de volver a hacer push. No uses `--force`.

Abre https://github.com/manlioooo/Monolito y comprueba que existe `catalogo_flask/` en `main`.

**Captura 01:** GitHub mostrando la carpeta `catalogo_flask` y el commit. Evita capturar cualquier pantalla de autenticación.

## 2. Conectarte a la VM

En PowerShell:

```powershell
ssh USUARIO_VM@IP_VM
```

Si normalmente accedes mediante un puerto redirigido de VirtualBox o una clave SSH, usa esos mismos parámetros (`-p PUERTO`, `-i RUTA_CLAVE`). Dentro de la VM:

```bash
cat /etc/os-release
whoami
hostname -I
```

Necesitas un usuario con `sudo` y salida a Internet para GitHub y paquetes. Esta guía no requiere abrir 5432 ni 5000 al exterior; solo utiliza tu acceso SSH existente.

## 3. Instalar paquetes: elige SOLO tu sistema operativo

**CentOS Stream 10:**

```bash
sudo dnf install -y git python3 python3-pip postgresql-server postgresql-contrib curl nano
```

Solo si PostgreSQL es una instalación nueva y todavía no tiene un clúster inicializado:

```bash
sudo postgresql-setup --initdb
```

Si indica que el directorio no está vacío o PostgreSQL ya estaba funcionando, no borres ni reinicialices sus datos. Continúa con el servicio existente:

```bash
sudo systemctl enable --now postgresql
sudo systemctl status postgresql --no-pager
```

**Ubuntu 24.04:**

```bash
sudo apt update
sudo apt install -y git python3 python3-venv python3-pip postgresql postgresql-contrib curl nano
sudo systemctl enable --now postgresql
pg_lsclusters
```

En Ubuntu el instalador crea normalmente el clúster; no ejecutes `postgresql-setup`. Un servicio genérico `active (exited)` debe complementarse con `pg_lsclusters` y la consulta siguiente.

**Ambos sistemas:**

```bash
python3 --version
psql --version
sudo -u postgres psql -c 'SELECT version();'
```

Python debe ser 3.10 o superior. Si usas CentOS 9 con Python 3.9 u otra distribución, ajusta primero la instalación de Python; no continúes suponiendo que cumple este requisito.

**Captura 02:** sistema operativo, versión de Python y respuesta de `SELECT version()`.

## 4. Descargar el proyecto

En la VM:

```bash
cd ~
git clone https://github.com/manlioooo/Monolito.git
cd ~/Monolito
git log -1 --oneline
ls catalogo_flask
ls db/01_schema.sql db/02_seed_30_per_table.sql
```

Si el repositorio es privado, Git pedirá usuario y token con acceso de lectura. No pongas el token en el comando. Si `~/Monolito` ya existe y es este repositorio, usa `cd ~/Monolito`, `git status` y `git pull --ff-only origin main` en lugar de clonar encima. Si tienes modificaciones locales, revísalas antes de actualizar.

**Captura 03:** último commit y listado de archivos descargados.

## 5. Crear usuario y base de datos

No ejecutes `db/00_create_database.sql`: pertenece a la configuración del proyecto Node.js. Para este ejercicio crearemos nombres independientes.

En la VM:

```bash
sudo -u postgres psql
```

Dentro de psql, escribe una instrucción por vez:

```sql
SET password_encryption = 'scram-sha-256';
CREATE ROLE catalogo_user LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
\password catalogo_user
CREATE DATABASE catalogo_flask OWNER catalogo_user ENCODING 'UTF8' TEMPLATE template0;
\connect catalogo_flask
REVOKE ALL ON DATABASE catalogo_flask FROM PUBLIC;
GRANT CONNECT, CREATE, TEMPORARY ON DATABASE catalogo_flask TO catalogo_user;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
ALTER SCHEMA public OWNER TO catalogo_user;
\du catalogo_user
\l catalogo_flask
\q
```

Cuando `\password` lo solicite, escribe dos veces una contraseña nueva y guárdala para usarla más adelante. No se muestra en pantalla. Si el rol o la base ya existen, detente y revisa si son de un intento anterior; no los borres ni importes el esquema sobre tablas existentes.

**Captura 04:** salida de `\du catalogo_user` y `\l catalogo_flask`, sin la contraseña.

## 6. Permitir contraseña desde localhost

Consulta dónde está la configuración real:

```bash
sudo -u postgres psql -Atc 'SHOW hba_file;'
```

Copia la ruta devuelta y abre ese archivo con `sudo nano RUTA_DEVUELTA`. Cerca del principio, antes de otras reglas `host` que coincidan con localhost, agrega:

```text
host    catalogo_flask    catalogo_user    127.0.0.1/32    scram-sha-256
```

Conserva las reglas existentes, especialmente las conexiones locales del usuario postgres. Guarda con Ctrl+O, Enter; sal con Ctrl+X.

```bash
sudo -u postgres psql -c 'SELECT pg_reload_conf();'
sudo -u postgres psql -c "SELECT line_number, error FROM pg_hba_file_rules WHERE error IS NOT NULL;"
psql -h 127.0.0.1 -U catalogo_user -d catalogo_flask -W -c 'SELECT current_user, current_database();'
```

La consulta de reglas debe devolver cero filas; la última debe mostrar `catalogo_user` y `catalogo_flask`. Introduce la contraseña del paso 5. Se usa `-h 127.0.0.1` para conectar por TCP y aplicar esa regla. PostgreSQL aplica la primera regla coincidente, por eso importa su posición.

**Captura 05:** conexión correcta con el rol de la aplicación.

## 7. Importar el esquema y los 30 registros de ejemplo

Ejecuta UNA SOLA VEZ en la base nueva, desde la VM:

```bash
cd ~/Monolito
psql -h 127.0.0.1 -U catalogo_user -d catalogo_flask -W -v ON_ERROR_STOP=1 -f db/01_schema.sql
psql -h 127.0.0.1 -U catalogo_user -d catalogo_flask -W -v ON_ERROR_STOP=1 -f db/02_seed_30_per_table.sql
psql -h 127.0.0.1 -U catalogo_user -d catalogo_flask -W -c '\dt'
psql -h 127.0.0.1 -U catalogo_user -d catalogo_flask -W -c 'SELECT isbn,title,price,stock FROM books ORDER BY id LIMIT 5;'
```

El seed muestra una tabla final con 30 registros en cada tabla de negocio listada. `user_sessions` es una tabla técnica del esquema y queda vacía. El primer libro tiene ISBN `9780000000001` y título `Fundamentos de Cloud Computing`.

Para comprobar los conceptos definidos por libro:

```bash
psql -h 127.0.0.1 -U catalogo_user -d catalogo_flask -W -c "SELECT b.isbn,c.term,bc.definition FROM book_concepts bc JOIN books b ON b.id=bc.book_id JOIN concepts c ON c.id=bc.concept_id WHERE b.isbn='9780000000001' ORDER BY c.id;"
```

No necesitas importar 03, 04, 05, 06 ni 07 para ejecutar Flask. La aplicación hace sus propias consultas y actualiza `updated_at`. Si falta `pgcrypto`, comprueba que instalaste `postgresql-contrib`. No ejecutes el seed si el esquema falló. Tampoco repitas el seed: no es idempotente.

**Captura 06:** conteos del seed y tablas. **Captura 07:** primer libro y sus definiciones.

## 8. Crear el entorno Python y probar el código

```bash
cd ~/Monolito/catalogo_flask
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python -m pip install 'gunicorn>=23,<24'
python -m unittest discover -s tests -v
```

Se esperan 11 pruebas y `OK`. Son unitarias con conexión simulada; las pruebas HTTP y SQL de los siguientes pasos verifican la base real. Flask se carga como `app:app`: módulo `app.py`, objeto Flask `app`.

**Captura 08:** las 11 pruebas y `OK`.

## 9. Configurar la conexión e iniciar la aplicación

En la misma terminal de la VM:

```bash
unset DATABASE_URL
export PGHOST=127.0.0.1
export PGPORT=5432
export PGDATABASE=catalogo_flask
export PGUSER=catalogo_user
read -rsp 'Contraseña de catalogo_user: ' PGPASSWORD
export PGPASSWORD
printf '\n'
python -c "from app import connect; c=connect(); print(c.execute('SELECT current_user, current_database()').fetchone()); c.close()"
gunicorn --workers 2 --bind 127.0.0.1:5000 --access-logfile - --error-logfile - app:app
```

Escribe la misma contraseña del paso 5. No se guarda en Git ni aparece en el historial del comando. La terminal queda ocupada mostrando Gunicorn. Déjala abierta durante la práctica. Si la cierras, vuelve a activar el entorno, exportar las variables e iniciar el servidor. No inicies también `python app.py`: ambos intentarían usar el puerto 5000.

**Captura 09:** comprobación de conexión y Gunicorn escuchando en `127.0.0.1:5000`, sin imprimir `PGPASSWORD` ni listar el entorno.

## 10. Abrir el catálogo desde Windows

En OTRA ventana de PowerShell de tu PC:

```powershell
ssh -N -L 8000:127.0.0.1:5000 USUARIO_VM@IP_VM
```

Si tu conexión SSH requiere `-p` o `-i`, añade los mismos parámetros que en el paso 2. La ventana permanece abierta, normalmente sin salida: es el túnel. El puerto 8000 de tu PC se redirige al 5000 de la VM. No tienes que cambiar Flask a `0.0.0.0`, abrir puertos HTTP ni desactivar firewalls.

Abre en el navegador de Windows:

```text
http://localhost:8000/api/books
http://localhost:8000/api/book/9780000000001
http://localhost:8000/api/book/author/1
http://localhost:8000/static/catalog.css
```

El catálogo es XML estilizado con CSS; no una página HTML. Las imágenes aparecen en el XML como rutas y atributos. El CSS actual muestra esas rutas como texto, no miniaturas. En el libro individual no existe el contenedor `library`, por lo que el estilo de fuente y fondo de `library` se verifica en `/api/books`.

**Captura 10:** catálogo completo con URL y colores visibles. **Captura 11:** libro 1, con conceptos y descripciones. **Captura 12:** filtro por autor. **Captura 13:** CSS con los valores exigidos; puedes usar varias imágenes para cubrir todo el archivo.

Para ver el XML sin CSS, usa `view-source:http://localhost:8000/api/book/9780000000001` en un navegador que admita `view-source`, o usa curl en el paso siguiente. Debe verse `<book isbn="9780000000001">`, autores, año, género, precio, stock, formato, imágenes y conceptos.

## 11. Probar los seis endpoints contra PostgreSQL real

Abre una SEGUNDA sesión SSH a la VM, manteniendo Gunicorn y el túnel en sus ventanas. Ejecuta:

```bash
cd ~/Monolito/catalogo_flask
mkdir -p ~/evidencias_catalogo
```

### 11.1 Catálogo, libro y autor: HTTP 200

```bash
curl -sS -i http://127.0.0.1:5000/api/books | tee ~/evidencias_catalogo/01_catalogo.txt
curl -sS -i http://127.0.0.1:5000/api/book/9780000000001 | tee ~/evidencias_catalogo/02_libro.txt
curl -sS -i http://127.0.0.1:5000/api/book/author/1 | tee ~/evidencias_catalogo/03_autor.txt
```

Para leer mejor el XML del libro:

```bash
curl -sS http://127.0.0.1:5000/api/book/9780000000001 | .venv/bin/python -c 'import sys; from xml.dom.minidom import parseString; print(parseString(sys.stdin.buffer.read()).toprettyxml())'
```

**Captura 14:** HTTP 200, `Content-Type: application/xml` y XML legible con ISBN, imagen y conceptos. Divide en varias capturas si no cabe.

### 11.2 Insertar: HTTP 201

El archivo incluido utiliza ids 1, existentes tras el seed. Ejecuta una sola vez:

```bash
curl -sS -i -X POST http://127.0.0.1:5000/api/book/insert -H 'Content-Type: application/json' --data-binary @example-book.json | tee ~/evidencias_catalogo/04_insertar.txt
psql -h 127.0.0.1 -U catalogo_user -d catalogo_flask -W -c "SELECT isbn,title,price,stock FROM books WHERE isbn='9781234567897';"
```

Esperado: `201 CREATED`, `Location: /api/book/9781234567897`, precio `249.90`, stock `12`. La consulta SQL demuestra que quedó persistido.

**Captura 15:** respuesta 201. **Captura 16:** fila insertada en PostgreSQL.

### 11.3 Actualizar: HTTP 200

```bash
curl -sS -i -X PATCH http://127.0.0.1:5000/api/book/update -H 'Content-Type: application/json' --data '{"isbn":"9781234567897","price":"199.90","stock":20}' | tee ~/evidencias_catalogo/05_actualizar.txt
psql -h 127.0.0.1 -U catalogo_user -d catalogo_flask -W -c "SELECT isbn,price,stock FROM books WHERE isbn='9781234567897';"
```

Esperado: precio `199.90`, stock `20`, tanto en XML como en SQL. Los demás datos permanecen. También puedes usar `PUT`; ambos métodos implementan actualización parcial.

**Captura 17:** HTTP 200 de actualización y valores persistidos.

### 11.4 Validación y conflicto: HTTP 400 y 409

Antes de borrar el libro:

```bash
curl -sS -i -X PATCH http://127.0.0.1:5000/api/book/update -H 'Content-Type: application/json' --data '{"isbn":"9781234567897","stock":-1}' | tee ~/evidencias_catalogo/06_stock_invalido.txt
curl -sS -i -X POST http://127.0.0.1:5000/api/book/insert -H 'Content-Type: application/json' --data-binary @example-book.json | tee ~/evidencias_catalogo/07_duplicado.txt
psql -h 127.0.0.1 -U catalogo_user -d catalogo_flask -W -c "SELECT isbn,stock FROM books WHERE isbn='9781234567897';"
```

Esperado: 400 para stock negativo; 409 para ISBN duplicado; stock todavía 20.

**Captura 18:** errores 400 y 409 con mensajes XML y stock intacto.

### 11.5 Borrar y verificar ausencia: HTTP 200 y 404

```bash
curl -sS -i -X DELETE http://127.0.0.1:5000/api/book/delete -H 'Content-Type: application/json' --data '{"isbn":"9781234567897"}' | tee ~/evidencias_catalogo/08_borrar.txt
curl -sS -i http://127.0.0.1:5000/api/book/9781234567897 | tee ~/evidencias_catalogo/09_no_encontrado.txt
psql -h 127.0.0.1 -U catalogo_user -d catalogo_flask -W -c "SELECT count(*) AS restantes FROM books WHERE isbn='9781234567897';"
psql -h 127.0.0.1 -U catalogo_user -d catalogo_flask -W -c 'SELECT count(*) AS total_catalogo FROM books;'
```

Esperado: 200 y `<deleted isbn="9781234567897" />`; consulta posterior 404; `restantes = 0`; catálogo vuelve a 30 libros. Solo se elimina el libro de prueba.

**Captura 19:** eliminación 200 y consulta 404. **Captura 20:** SQL con cero coincidencias y total 30.

## 12. Guardar capturas y descargar evidencias

En Windows crea una carpeta `evidencias_catalogo` en tu Escritorio. Usa `Win + Shift + S` y guarda cada captura con el número y descripción del paso, por ejemplo `10_catalogo_css.png`. Incluye el comando o la URL y su resultado; mantén el texto legible. Los archivos de curl son evidencia textual, no sustituyen screenshots.

Desde otra ventana PowerShell puedes descargar los archivos de texto:

```powershell
scp -r USUARIO_VM@IP_VM:evidencias_catalogo "$env:USERPROFILE\Desktop"
```

Si usas puerto SSH distinto, en scp el parámetro es `-P PUERTO` (P mayúscula). Si tu Escritorio está redirigido a OneDrive, sustituye el destino por su ruta real. No captures contraseñas, tokens ni claves.

Para terminar, Ctrl+C en Gunicorn y en el túnel SSH. La base permanece guardada. Para volver a mostrar el trabajo, repite los pasos 9 y 10; no recrees la base ni repitas el seed.

## Problemas frecuentes

| Mensaje o síntoma | Acción |
| --- | --- |
| `password authentication failed` | Verifica la contraseña y que el usuario/base sean los de esta guía. Puedes restablecerla con `sudo -u postgres psql` y `\password catalogo_user`. |
| `Ident authentication failed` | Revisa el orden de la regla de localhost del paso 6, recarga PostgreSQL y usa `-h 127.0.0.1`. |
| `relation ... already exists` | El esquema ya se importó. No vuelvas a ejecutar los scripts a ciegas. |
| `ModuleNotFoundError` | Activa `.venv` y ejecuta desde `~/Monolito/catalogo_flask`. |
| HTTP 503 | Verifica PostgreSQL, las variables de conexión y que Gunicorn se inició en la misma terminal donde se exportaron. |
| HTTP 409 en la primera inserción | El libro de prueba ya existe por una ejecución previa. Consúltalo y continúa o elimina únicamente ese ISBN antes de repetir. |
| `Address already in use` | Comprueba `ss -ltnp 'sport = :5000'`; no ejecutes dos servidores en el mismo puerto. |
| El navegador no conecta | Mantén abiertas las ventanas Gunicorn/túnel y usa `localhost:8000`, no la IP de la VM con puerto 8000. |
| Puerto 8000 ocupado en Windows | Crea el túnel con `-L 8001:127.0.0.1:5000` y navega a `localhost:8001`. |
| El catálogo no tiene estilos | Comprueba que `/static/catalog.css` responde 200 y que el XML contiene `xml-stylesheet`; abre `/api/books`. |

Esta es una ejecución para demostración con Gunicorn en primer plano; no configura arranque automático tras reiniciar la VM. La API del ejercicio no tiene autenticación y se mantiene accesible mediante SSH, sin publicarla en Internet.

Referencias verificadas: [GitHub: subir un repositorio local](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github), [PostgreSQL en Red Hat/CentOS](https://www.postgresql.org/download/linux/redhat/), [orden de reglas pg_hba.conf](https://www.postgresql.org/docs/17/auth-pg-hba-conf.html), [Flask con Gunicorn](https://flask.palletsprojects.com/en/stable/deploying/gunicorn/).
