# Despliegue en CentOS Stream 10 con NGINX

## Instalar paquetes

```bash
sudo dnf update -y
sudo dnf install -y nginx postgresql-server postgresql-contrib nodejs npm git tar nano
node --version
npm --version
```

Verifica que Node sea 20 o superior. Si el repositorio de la imagen entrega una versión menor, utiliza un repositorio corporativo/aprobado y documenta la fuente; no ejecutes scripts remotos sin revisarlos.

## PostgreSQL y proyecto

```bash
sudo postgresql-setup --initdb
sudo systemctl enable --now postgresql
sudo -u postgres psql -f db/00_create_database.sql
psql -U library_app -W -d online_library -f db/01_schema.sql
# continuar 02...06 en el orden documentado
npm ci --omit=dev
```

Ajusta `pg_hba.conf` para contraseña SCRAM únicamente desde loopback, reinicia PostgreSQL y crea `.env` con permisos `600`. Configura `HOST=127.0.0.1`, `BASE_PATH=/library` y `COOKIE_SECURE=false` mientras la práctica use HTTP; cambia este último valor a `true` al habilitar HTTPS. No copies el archivo a la evidencia pública.

## Servicio systemd

Copia `deploy/library.service` como `/etc/systemd/system/library.service`, ajusta `User`, `WorkingDirectory` y `EnvironmentFile`, y ejecuta:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now library
sudo systemctl status library --no-pager
curl -I http://127.0.0.1:3000/library/login
```

## Reverse proxy

Copia `deploy/nginx-library.conf` a `/etc/nginx/conf.d/library.conf`:

```bash
sudo nginx -t
sudo setsebool -P httpd_can_network_connect 1
sudo systemctl enable --now nginx
sudo systemctl reload nginx
curl -I http://IP_DEL_SERVIDOR/library/login
```

NGINX conserva el URI `/library/...` porque `proxy_pass` no añade una URI. Envía Host/IP original y protocolo a Express. La aplicación escucha sólo en loopback; NGINX es el punto público, donde debe configurarse TLS en producción. Esta semántica está documentada por [NGINX Reverse Proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy).

## Checklist externo

- Login/registro y redirección del visitante.
- CSS e imágenes bajo `/library`.
- Sesiones y CSRF después del proxy.
- Formularios y redirecciones conservan el prefijo.
- JPG, PNG y WebP se cargan y sirven.
- Puerto 3000 no responde desde Internet.
- Ventana incógnito abre la URL sin recursos rotos.
