# Tarea 2d - Revisión final de seguridad

| # | Amenaza/error | Control aplicado | Evidencia/prueba | Riesgo residual |
|---:|---|---|---|---|
| 1 | SQL Injection | Valores exclusivamente parametrizados; identificadores dinámicos salen de whitelist. | Revisar `services/`; TP-18 usa `' OR 1=1 --`. | Un futuro cambio podría concatenar SQL; requiere revisión de código. |
| 2 | Robo de contraseña | bcrypt coste 12; contraseña nunca se registra ni devuelve. | `routes/auth.js`; inspección DB muestra sólo hash. | Contraseñas débiles/reutilizadas fuera del sistema. |
| 3 | Acceso administrativo | `requireAdmin` en todo el router; 403 controlado. | TP-05 y TP-06. | Sesión de administrador robada conserva permisos hasta expirar/logout. |
| 4 | CSRF | Token aleatorio por sesión y comparación temporalmente segura en escrituras. | TP-17 sin token devuelve 403. | XSS podría leer/interactuar dentro del origen. |
| 5 | Archivo peligroso | MIME permitido, tamaño máximo, UUID, directorio separado y extensión calculada. | TP-15/TP-16. | MIME puede falsificarse; producción requiere magic bytes y antivirus. |
| 6 | Credenciales publicadas | `.env` ignorado, `.env.example` sin secreto y paquetes excluyen secretos. | Revisar `.gitignore` y contenido TAR.GZ. | Capturas manuales podrían revelar datos; requieren revisión humana. |
| 7 | Segundo administrador | Índice único parcial en PostgreSQL, además de controles UI. | TP-12 obtiene SQLSTATE 23505. | El administrador existente sigue siendo un punto privilegiado único. |
| 8 | Sesión insegura | Store PostgreSQL, cookie `httpOnly`, `sameSite=lax`, `COOKIE_SECURE=true` al habilitar HTTPS y expiración 8 h. | Cabecera Set-Cookie en TP-02. | La prueba académica por HTTP requiere `COOKIE_SECURE=false`; debe cambiarse al activar TLS. |
| 9 | Exposición de errores | Handler general registra interno y presenta mensaje genérico; sin `x-powered-by`. | TP-19 provoca error controlado. | Logs necesitan permisos/rotación del sistema operativo. |
| 10 | Eliminación accidental | FK RESTRICT/CASCADE explícitas, confirmación UI y transacciones. | TP-11 y TP-14. | El administrador puede confirmar por error; se recomiendan backups/PITR. |
| 11 | Exposición directa de Node | `HOST=127.0.0.1`; firewall sólo permite HTTP/HTTPS al proxy. | `ss -lntp` y TP-20. | Configuración manual incorrecta de HOST/firewall. |
| 12 | Abuso de privilegios DB | `library_app` no es superusuario, no crea bases/roles y sólo posee su base. | `\du library_app`; `00_create_database.sql`. | Como propietario puede alterar objetos de `online_library`; es un compromiso aceptado por la consigna del usuario. |

La revisión debe completarse en la VM con capturas censuradas de TP-05, TP-12, TP-15, TP-17 y `\du library_app`. No se deben capturar contraseñas ni `.env`.
