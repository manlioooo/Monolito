# Tarea 2a - Síntesis de normalización hasta 4FN

## Estructura no normalizada

`LIBRO(ISBN, título, año, precio, stock, formato, categoría, {autores}, {géneros}, {imágenes}, {concepto, definición, capítulo, página})` contiene grupos repetitivos y hechos multivaluados independientes.

## 1FN

Se exige atomicidad: una fila por combinación produciría repetición de datos del libro y un producto cartesiano entre autores, géneros, imágenes y conceptos. No se guardan listas delimitadas ni columnas `autor1`, `autor2`.

## 2FN

Al usar una clave compuesta gigante, título/precio/stock dependen sólo de ISBN; nombre del autor depende sólo del autor; definición depende de libro+concepto. Se separan entidades y relaciones para que cada atributo dependa de toda su clave.

## 3FN / BCNF

Formato y categoría son catálogos porque sus nombres/descripciones dependen de sus identificadores, no del libro. `users.email`, `books.isbn`, `authors.name`, `genres.name`, `concepts.term` y rutas de imagen son claves candidatas protegidas con UNIQUE. En cada relación determinante no trivial, el determinante es clave candidata.

## 4FN

Para un libro existen dependencias multivaluadas independientes:

- `book_id ↠ author_id`
- `book_id ↠ genre_id`
- `book_id ↠ image_id`
- `book_id ↠ concept_id` con atributos propios de la relación

Guardarlas juntas generaría combinaciones espurias. Las tablas `book_authors`, `book_genres`, `book_images` y `book_concepts` expresan por separado cada hecho. En `book_concepts`, definición/capítulo/página dependen de la clave completa `(book_id, concept_id)`. En las relaciones puras no queda una dependencia multivaluada no trivial cuyo determinante no sea superclave. El modelo alcanza 4FN.

## Justificación de tablas puente

| Tabla | Hecho representado | Clave | Evita |
|---|---|---|---|
| `book_authors` | Autor participa en libro | libro+autor | listas y duplicación de biografía |
| `book_genres` | Género clasifica libro | libro+género | columnas repetidas y combinaciones espurias |
| `book_concepts` | Libro define concepto en contexto | libro+concepto | definición global incorrecta |
| `book_images` | Libro posee una imagen con metadatos | id; FK libro | rutas repetidas y límite artificial de imágenes |

El detalle celda por celda se entrega en `NORMALIZATION_4FN.xlsx` y el modelo final en `DB_DESIGN_ER_4FN.png`.
