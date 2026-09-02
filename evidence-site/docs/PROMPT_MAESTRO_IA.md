# Prompt maestro para una evolución controlada

Usa este formato para solicitar una sola mejora pequeña, revisable y reversible. No incluyas credenciales ni datos personales.

```text
Contexto: aplicación monolítica Express + EJS + PostgreSQL, sin API y con HTML server-side.
Objetivo pequeño y verificable: [una mejora concreta].
Restricciones: conservar la arquitectura, usar SQL parametrizado, validar en servidor, respetar /library y no introducir JSON/XML de intercambio.
Archivos previstos: [lista].
Criterios de aceptación: [resultados observables].
Riesgos que debes revisar: [integridad, seguridad, compatibilidad].
Pruebas obligatorias: [comandos/casos].
Entrega: explica el cambio, archivos modificados, riesgo introducido, pruebas y resultado; no afirmes pruebas que no ejecutaste.
```

## Prompt exacto utilizado para Tarea 2e

```text
Contexto: aplicación monolítica Express + EJS + PostgreSQL, sin API y con HTML server-side.
Objetivo pequeño y verificable: permitir guardar y mostrar una referencia opcional de capítulo y página en cada definición libro-concepto.
Restricciones: conservar la relación normalizada book_concepts; usar SQL parametrizado; validar en servidor; respetar /library; no introducir JSON/XML de intercambio.
Archivos previstos: db/01_schema.sql, db/02_seed_30_per_table.sql, db/04_stored_procedures.sql, db/06_views.sql, services/catalogService.js, routes/admin.js y vistas EJS de libro.
Criterios de aceptación: el administrador captura capítulo/página, el UPSERT los actualiza y el detalle los muestra sólo cuando existen.
Riesgos que debes revisar: compatibilidad del esquema, longitud de entradas, XSS y pérdida de datos durante UPSERT.
Pruebas obligatorias: validación de sintaxis JavaScript, compilación EJS, inspección de SQL parametrizado y caso manual de alta/edición.
Entrega: explica el cambio, archivos modificados, riesgo introducido, pruebas y resultado; no afirmes pruebas que no ejecutaste.
```
