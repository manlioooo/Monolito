# Catálogo Flask y PostgreSQL

Una sola aplicación en `app.py`, sin Blueprints. Usa sin modificar las tablas de `../db/01_schema.sql`. La aplicación Node.js del directorio superior se conserva por separado.

Para subir a GitHub y ejecutar en una VM Linux con PostgreSQL, sigue [la guía completa de VM y capturas](GUIA_VM.md).

## Ejecutar

Requisitos: Python 3.10 o superior y PostgreSQL con una base dedicada para este ejercicio. Desde esta carpeta, en PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
createdb -U postgres catalogo
psql -U postgres -d catalogo -v ON_ERROR_STOP=1 -f ../db/01_schema.sql
# Opcional: cargar los datos de ejemplo del proyecto.
psql -U postgres -d catalogo -v ON_ERROR_STOP=1 -f ../db/02_seed_30_per_table.sql
$env:DATABASE_URL = 'postgresql://postgres:TU_PASSWORD@localhost:5432/catalogo'
.\.venv\Scripts\python.exe app.py
```

Si la base ya contiene el esquema, omite su creación e importación. La variable `DATABASE_URL` se lee del entorno; no se carga automáticamente un archivo `.env`. Codifica los caracteres especiales de usuario/contraseña como componentes de URL. También se admiten las variables estándar de conexión de PostgreSQL cuando `DATABASE_URL` no está definida.

Abre http://127.0.0.1:5000/ para visualizar el catálogo. `/` redirige al XML de `/api/books`, que enlaza `static/catalog.css` mediante `xml-stylesheet`.

## Endpoints

| Método | Ruta | Resultado |
| --- | --- | --- |
| GET | `/api/books` | Catálogo `<library><books>…</books></library>` |
| GET | `/api/book/<isbn>` | Un `<book isbn="…">` o 404 |
| GET | `/api/book/author/<author_id>` | Libros del autor, o colección vacía |
| POST | `/api/book/insert` | Inserta y devuelve el libro, 201 y cabecera Location |
| PUT / PATCH | `/api/book/update` | Modificación parcial identificada por ISBN, 200 |
| DELETE | `/api/book/delete` | Elimina el libro y sus relaciones, 200 |

Las escrituras reciben JSON con `Content-Type: application/json`; todas las respuestas de la API son XML. Los errores de validación devuelven 400, los conflictos de unicidad 409, un tipo de contenido incorrecto 415 y la indisponibilidad de PostgreSQL 503. GET no modifica datos.

```powershell
curl.exe http://127.0.0.1:5000/api/books
curl.exe http://127.0.0.1:5000/api/book/author/1
curl.exe -X POST http://127.0.0.1:5000/api/book/insert -H "Content-Type: application/json" --data-binary "@example-book.json"
curl.exe http://127.0.0.1:5000/api/book/9781234567897
'{"isbn":"9781234567897","stock":20,"price":"199.90"}' | curl.exe -X PATCH http://127.0.0.1:5000/api/book/update -H "Content-Type: application/json" --data-binary '@-'
'{"isbn":"9781234567897"}' | curl.exe -X DELETE http://127.0.0.1:5000/api/book/delete -H "Content-Type: application/json" --data-binary '@-'
```

El ejemplo requiere que existan formato, categoría, autor, género y concepto con id 1. Sustituye esos identificadores por los de tu base. Los endpoints no crean registros maestros.

Al actualizar, los campos omitidos se conservan. Las listas enviadas reemplazan la relación completa; `images: []` y `concepts: []` la vacían. Los autores y géneros enviados deben contener al menos un elemento. El ISBN identifica al libro y no se modifica. `category_id` es obligatorio al insertar porque lo exige el esquema, aunque no figure en el enunciado. La validación del ISBN respeta la expresión del SQL entregado, sin añadir una validación de dígito de control diferente.

El XML incluye todos los autores y géneros, año, precio con dos decimales, stock, formato, categoría, descripción, imágenes y conceptos. Cada concepto incluye el término y la `definition` específica de `book_concepts` como `<description>`. ElementTree escapa el texto XML. Las imágenes se representan por sus rutas y atributos; el CSS muestra dichas rutas como texto, no descarga ni renderiza los archivos de imagen.

Las consultas usan parámetros, las modificaciones son atómicas y el borrado de relaciones aprovecha `ON DELETE CASCADE` del esquema. La aplicación no incorpora autenticación porque no es parte del ejercicio; ejecútala localmente. El servidor arranca en `127.0.0.1` sin depuración.

## Pruebas

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
```

Las pruebas unitarias verifican XML, rutas, validación y errores con una conexión simulada. No reemplazan una prueba de integración contra PostgreSQL. Para verificar persistencia real, ejecuta la secuencia de curl anterior con una base de pruebas: comprueba el stock actualizado, elimina el libro y verifica que su consulta devuelve 404.

Referencias: [Flask](https://flask.palletsprojects.com/en/stable/quickstart/) y [transacciones de Psycopg](https://www.psycopg.org/psycopg3/docs/basic/transactions.html).
