# Requisitos, actores, supuestos y riesgos

## Requisitos funcionales

| ID | Requisito | Criterio de aceptación |
|---|---|---|
| RF-01 | Registrar usuarios regulares | Correo único, contraseña de 8+ caracteres con hash bcrypt y rol `user` forzado por servidor. |
| RF-02 | Iniciar y cerrar sesión | Credenciales válidas crean sesión; logout destruye la sesión. |
| RF-03 | Consultar catálogo autenticado | Visitante es redirigido a login; usuario activo ve libros, precio y stock. |
| RF-04 | Buscar por ISBN o título | La búsqueda parcial, sin distinguir mayúsculas, utiliza un parámetro SQL. |
| RF-05 | Consultar detalle y conceptos | Muestra autores, géneros, imágenes y definición contextual con capítulo/página. |
| RF-06 | CRUD de libros | Administrador puede crear, leer, actualizar y eliminar con validación y mensajes. |
| RF-07 | CRUD de catálogos | Administrador gestiona autores, géneros, formatos, categorías y conceptos. |
| RF-08 | Gestionar relaciones multivaluadas | Administrador asigna varios autores y géneros sin listas en `books`. |
| RF-09 | Gestionar conceptos por libro | Alta/edición por `UPSERT` y eliminación de definición, capítulo y página. |
| RF-10 | Gestionar imágenes | Carga JPG/PNG/WebP, edición de texto alternativo/orden/portada y eliminación. |
| RF-11 | Administrar usuarios | Administrador consulta, crea, modifica, activa/desactiva y elimina usuarios. |
| RF-12 | Controlar precio y stock | Sólo admite precio y stock no negativos. |
| RF-13 | Administrador único | PostgreSQL rechaza cualquier segundo rol `admin`. |
| RF-14 | Ejecutar bajo `/library` | Formularios, recursos, sesiones y redirecciones funcionan con ese prefijo. |

## Requisitos no funcionales

| ID | Requisito | Criterio de aceptación |
|---|---|---|
| RNF-01 | Seguridad | CSRF, bcrypt, cookies seguras, Helmet, autorización, secretos fuera de Git y uploads limitados. |
| RNF-02 | Integridad | PK, FK, UNIQUE, CHECK, índices y transacciones protegen todas las escrituras. |
| RNF-03 | Mantenibilidad | Rutas, servicios, middleware, configuración, vistas y estáticos tienen responsabilidades separadas. |
| RNF-04 | Rendimiento básico | Pool de 10 conexiones e índices de búsqueda/uniones; respuestas server-side sin llamadas API. |
| RNF-05 | Usabilidad | Navegación responsive, mensajes controlados, etiquetas y texto alternativo. |
| RNF-06 | Disponibilidad | Servicio systemd reiniciable y PostgreSQL con respaldo operativo documentado. |
| RNF-07 | Trazabilidad | Errores internos se registran sin exponer SQL/stack; matriz enlaza pruebas con requisitos. |
| RNF-08 | Despliegue | Node escucha sólo en `127.0.0.1:3000`; NGINX publica `/library`. |
| RNF-09 | Privacidad | `.env`, llaves, tokens, sesiones y credenciales se excluyen de paquetes/publicación. |
| RNF-10 | Arquitectura | Una unidad desplegable Express/EJS/pg; sin REST, GraphQL, SOAP, microservicios, JSON o XML de intercambio. |

## Actores y permisos

| Actor | Permitido | Debe rechazarse |
|---|---|---|
| Visitante | Login, registro y archivos públicos necesarios para esas pantallas. | Catálogo, detalle y cualquier ruta `/admin`. |
| Usuario registrado | Catálogo, búsqueda, detalle, conceptos y logout. | Escrituras administrativas y cambio de rol. |
| Administrador | Todo lo anterior y CRUD completo administrable. | Crear un segundo administrador; eliminar su propia cuenta activa. |

## Supuestos y restricciones

- PostgreSQL, Node.js y NGINX se instalan desde el inicio en la misma VM Compute Engine con CentOS Stream 10; la conexión DB no sale a Internet.
- `library_app` es propietario sólo de `online_library`, sin `SUPERUSER`, `CREATEDB` ni `CREATEROLE`.
- La evidencia real de GCP, psql y navegador debe capturarse después de usar credenciales del estudiante.
- El prefijo de producción es `/library`; `BASE_PATH` permite conservarlo en local.
- `package.json` existe sólo para administración npm; no representa intercambio de datos.

## Riesgos iniciales

Acceso no autorizado, SQL Injection, CSRF, archivo malicioso, credenciales publicadas, segundo administrador por carrera, eliminación accidental, sesión robada, ruta interna expuesta y evidencia con datos sensibles. Los controles y riesgo residual están en `SECURITY_REVIEW.md`.
