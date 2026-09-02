# Registro de cambios asistidos por IA

## 2026-09-01 - IA-2026-09-01-01

- Añadidos `chapter_reference` y `page_reference` a `book_concepts`.
- Actualizados seed, procedimiento almacenado y vista de conceptos.
- Actualizado UPSERT administrativo con validación y parámetros.
- Actualizadas vistas de administración y detalle para capturar/mostrar la referencia.
- Riesgo: requiere recrear o migrar una base existente.
- Resultado esperado: la referencia aparece sólo cuando existe y sigue dependiendo de `(book_id, concept_id)`.
- Estado: código implementado; validación estática incluida; ejecución DB/HTTP pendiente en la VM del estudiante.
