# Tarea 2b - Matriz de pruebas e integridad

Los resultados `Validado estáticamente` corresponden a comprobaciones realizadas sin PostgreSQL. Los casos `Pendiente VM` deben ejecutarse en la instancia y completar resultado observado, fecha y captura; no se inventa evidencia.

| ID | Req. | Tipo | Precondición/entrada | Pasos resumidos | Resultado esperado | Resultado observado | Estado/evidencia |
|---|---|---|---|---|---|---|---|
| TP-01 | RF-01 | Positiva | Correo nuevo, clave válida | Registrar | Cuenta `user`, mensaje y login | Plantilla/ruta/SQL revisados | Validado estáticamente |
| TP-02 | RF-02 | Positiva | Usuario activo | Login correcto | Sesión regenerada y catálogo | Pendiente HTTP+DB | Pendiente VM |
| TP-03 | RF-02 | Negativa | Clave incorrecta | Login | Mensaje genérico, sin sesión | Pendiente HTTP+DB | Pendiente VM |
| TP-04 | RF-03 | Autorización | Sin sesión | GET `/library/` | Redirección a login | Middleware presente | Validado estáticamente |
| TP-05 | RF-07 | Autorización | Usuario regular | GET `/library/admin` | 403 controlado | Middleware presente | Validado estáticamente |
| TP-06 | RF-07 | Positiva | Administrador | GET `/library/admin` | Panel y conteos | Pendiente HTTP+DB | Pendiente VM |
| TP-07 | RF-04 | Positiva | Buscar `Cloud` | Enviar búsqueda | Coincidencia por título | SQL usa `$1` e ILIKE | Validado estáticamente |
| TP-08 | RF-04 | Positiva | ISBN existente | Buscar ISBN | Libro exacto visible | Pendiente HTTP+DB | Pendiente VM |
| TP-09 | RF-06 | CRUD | Datos válidos | Alta/consulta/edición/baja libro | Cambios persistentes y mensajes | Pendiente HTTP+DB | Pendiente VM |
| TP-10 | RF-08 | Relación | 2 autores y 2 géneros | Editar libro | 4 relaciones sin duplicados | Transacción revisada | Validado estáticamente |
| TP-11 | RF-09 | CRUD | IaaS, definición, cap./pág. | Guardar/actualizar/quitar | Relación cambia, concepto maestro permanece | UPSERT parametrizado revisado | Validado estáticamente |
| TP-12 | RF-13 | Negativa DB | Ya existe admin | Ejecutar inserción segundo admin | SQLSTATE 23505 | Pendiente psql | Pendiente VM |
| TP-13 | RF-12 | Negativa DB | stock=-1 / precio=-1 | INSERT/UPDATE | SQLSTATE 23514 | Bloques de prueba presentes | Validado estáticamente |
| TP-14 | RNF-02 | Negativa DB | FK 999999 / borrar maestro usado | Ejecutar sentencia | SQLSTATE 23503 | Bloques de prueba presentes | Validado estáticamente |
| TP-15 | RF-10 | Archivos | PDF renombrado `.jpg` | Intentar cargar | Rechazo controlado | Pendiente navegador | Pendiente VM |
| TP-16 | RF-10 | Archivos | Imagen mayor a 5 MB | Intentar cargar | Rechazo por tamaño | Límite configurado | Validado estáticamente |
| TP-17 | RNF-01 | Seguridad | POST sin `_csrf` | Enviar formulario | 403 controlado | Comparación segura revisada | Validado estáticamente |
| TP-18 | RNF-01 | Seguridad | Búsqueda `' OR 1=1 --` | Buscar | Se trata como texto; no altera SQL | Parámetro `$1` revisado | Validado estáticamente |
| TP-19 | RNF-07 | Error | Provocar UNIQUE/FK | Enviar formulario | Mensaje controlado sin stack/SQL completo | Handler revisado | Validado estáticamente |
| TP-20 | RF-14 | Despliegue | NGINX activo | Acceso externo `/library` y prueba :3000 | App funciona; :3000 no expuesto | Pendiente GCP | Pendiente VM |
| TP-21 | RF-10 | CRUD imagen | Imagen existente | Editar alt/orden/portada y borrar | Metadatos cambian; archivo se elimina | Ruta y formulario presentes | Validado estáticamente |
| TP-22 | RF-07 | CRUD maestros | Cada catálogo | Alta/lectura/edición/baja | Todos operables; FK protege usados | Interfaz genérica revisada | Validado estáticamente |
| TP-23 | RF-11 | CRUD usuarios | Admin autenticado | Crear/editar/desactivar/eliminar | Cambios persistentes; autoeliminación rechazada | Rutas revisadas | Validado estáticamente |
| TP-24 | RNF-05 | Navegación | Móvil/escritorio | Recorrer pantallas | Sin enlaces rotos ni contenido crítico cortado | Pendiente navegador | Pendiente VM |

Las sentencias negativas reproducibles están en `db/07_integrity_verification.sql`. Nombra capturas como `TP-XX-descripcion.png` y escribe debajo contexto, entrada y conclusión.
