# Registro de decisiones de ingeniería

## ADR-01 - Monolito modular

**Necesidad/problema:** implementar catálogo, autenticación y CRUD con un equipo de una persona. **Alternativas:** aplicación monolítica, frontend/API desacoplados o microservicios. **Decisión:** un proceso Express con módulos internos. **Justificación:** reduce despliegues, red distribuida y consistencia eventual; las transacciones permanecen locales. **Riesgo/limitación:** escala y despliegue conjuntos. **Evidencia:** `app.js` monta rutas, middleware, EJS y acceso `pg` en una unidad; `npm start` crea un solo proceso.

## ADR-02 - Acceso PostgreSQL directo y parametrizado

**Necesidad/problema:** persistencia relacional con integridad fuerte sin API. **Alternativas:** ORM, consultas directas o servicio de datos separado. **Decisión:** `pg`, pool central y SQL `$1...$n`. **Justificación:** hace explícito el diseño normalizado y permite aprovechar restricciones/transacciones. **Riesgo/limitación:** mayor conocimiento SQL y acoplamiento a PostgreSQL. **Evidencia:** `config/db.js`, `services/` y prueba TP-18 de caracteres especiales.

## ADR-03 - HTML server-side con EJS

**Necesidad/problema:** interfaz sin JSON/XML entre frontend y backend. **Alternativas:** SPA, archivos HTML estáticos o plantillas server-side. **Decisión:** EJS y formularios URL-encoded/multipart. **Justificación:** navegación simple, autorización antes de renderizar y menor JavaScript cliente. **Riesgo/limitación:** cada acción suele recargar página y hay que cuidar el prefijo de despliegue. **Evidencia:** 13 plantillas EJS compiladas y rutas bajo `BASE_PATH=/library`.

## ADR-04 - 4FN con relaciones independientes

**Necesidad/problema:** autores, géneros, imágenes y conceptos son hechos multivaluados independientes. **Alternativas:** listas/arrays, JSON o tablas puente. **Decisión:** `book_authors`, `book_genres`, `book_concepts` y `book_images`. **Justificación:** evita productos cartesianos y anomalías; cada relación expresa un hecho. **Riesgo/limitación:** más joins y pantallas de administración. **Evidencia:** `01_schema.sql`, `NORMALIZATION_4FN.xlsx` y diagrama ER.

## ADR-05 - Sesión en PostgreSQL

**Necesidad/problema:** evitar sesiones sólo en memoria y permitir reinicios. **Alternativas:** MemoryStore, Redis o PostgreSQL. **Decisión:** `connect-pg-simple` y tabla técnica `user_sessions`. **Justificación:** reutiliza infraestructura disponible y permite más de una instancia. **Riesgo/limitación:** I/O adicional y limpieza de sesiones vencidas. **Evidencia:** cookie opaca; el navegador no intercambia JSON con el servidor.

## ADR-06 - Imágenes en filesystem, metadatos en DB

**Necesidad/problema:** varias imágenes por libro con portada y texto alternativo. **Alternativas:** binarios en PostgreSQL, filesystem o almacenamiento de objetos. **Decisión:** filesystem `uploads/` con UUID y metadatos relacionales. **Justificación:** simple para una VM académica y evita inflar la base. **Riesgo/limitación:** exige backup coordinado y no escala horizontalmente sin volumen compartido. **Condición de cambio:** más de una VM o CDN justificaría Cloud Storage.

## ADR-07 - `library_app` propietario limitado

**Necesidad/problema:** el estudiante requiere que el usuario no-superusuario cree todos los objetos. **Alternativas:** ejecutar DDL con `postgres`, rol propietario separado o propietario `library_app`. **Decisión:** `postgres` sólo crea rol/base; `library_app` posee base/esquema y crea todo. **Justificación:** cumple el flujo solicitado sin ejecutar la aplicación como superusuario. **Riesgo/limitación:** una inyección con privilegios de propietario podría alterar el esquema. **Evidencia:** `00_create_database.sql` conserva `NOSUPERUSER NOCREATEDB NOCREATEROLE`.
