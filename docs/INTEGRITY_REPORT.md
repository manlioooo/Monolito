# Informe de integridad

`db/07_integrity_verification.sql` verifica claves primarias, foráneas, `UNIQUE`, `CHECK` e índices; cada prueba destructiva se ejecuta en un bloque que captura el error y no altera datos.

La prueba del segundo administrador intenta insertar otra fila `role='admin'`. PostgreSQL debe generar SQLSTATE `23505` con un mensaje equivalente a:

```text
ERROR: duplicate key value violates unique constraint "ux_users_single_admin"
DETAIL: Key (role)=(admin) already exists.
```

El texto exacto puede variar según idioma/versión, pero la restricción y SQLSTATE son estables. Otras pruebas documentan ISBN duplicado (`23505`), precio y stock negativos (`23514`), FK inexistente y eliminación protegida por `RESTRICT` (`23503`). Los `NOTICE` reales deben capturarse en la VM; el documento no inventa salidas que aún no se ejecutaron.
