# Historial de prompts de IA

## IA-2026-09-01-01 - Referencia de capítulo y página

**Prompt exacto:** conservado en `docs/PROMPT_MAESTRO_IA.md`, sección “Prompt exacto utilizado para Tarea 2e”.

**Respuesta relevante resumida:** se propuso ampliar `book_concepts` con `chapter_reference` y `page_reference`, extender el procedimiento/UPSERT, seleccionar esos campos en el servicio y agregarlos a formularios y detalle. Se mantuvo la definición en la relación, no en `concepts`, por lo que se conserva 4FN.

**Revisión humana requerida:** confirmar que capítulo/página son opcionales, longitudes 80/40 suficientes y que el formato de página admite rangos como `45-49`.

**Archivos modificados:** `db/01_schema.sql`, `db/02_seed_30_per_table.sql`, `db/04_stored_procedures.sql`, `db/06_views.sql`, `services/catalogService.js`, `routes/admin.js`, `views/admin/books/form.ejs`, `views/catalog/detail.ejs`.

**Riesgo introducido:** una base ya creada necesita migración antes de ejecutar el código nuevo; ejecutar desde cero no presenta incompatibilidad. El texto se escapa por defecto en EJS. El UPSERT parametrizado evita concatenación.

**Pruebas ejecutadas:** `node --check` y compilación EJS se ejecutan en la validación final. La prueba SQL/HTTP queda marcada como pendiente de PostgreSQL real, sin afirmar un resultado inexistente.
