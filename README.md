# Librería monolítica - guía completa en CentOS Stream 10

Todo el desarrollo, instalación, configuración, ejecución y despliegue de esta entrega se documenta para una instancia **Compute Engine con CentOS Stream 10**. La aplicación utiliza Node.js, Express, EJS y acceso directo a PostgreSQL mediante `pg`; no expone APIs ni intercambia JSON/XML con el navegador.

## 1. Crear la instancia CentOS Stream 10

Desde Google Cloud SDK configura tu proyecto y crea la VM. Sustituye `TU_PROYECTO` si todavía no lo configuraste:

```bash
gcloud auth login
gcloud config set project TU_PROYECTO
gcloud services enable compute.googleapis.com

gcloud compute firewall-rules create allow-library-web \
  --network=default \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:80,tcp:443 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=library-web

gcloud compute instances create library-vm \
  --zone=us-central1-a \
  --machine-type=e2-small \
  --image-family=centos-stream-10 \
  --image-project=centos-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-balanced \
  --tags=library-web

gcloud compute ssh library-vm --zone=us-central1-a
```

A partir de este punto, todos los comandos se ejecutan dentro de CentOS Stream 10. Los detalles están en `docs/GCP_COMMANDS.md`.

## 2. Actualizar CentOS e instalar herramientas

```bash
sudo dnf update -y
sudo dnf install -y git curl tar nano nginx postgresql-server postgresql-contrib nodejs npm
```

Comprueba versiones:

```bash
cat /etc/centos-release
node --version
npm --version
psql --version
nginx -v
```

La aplicación requiere Node.js 20 o superior. Si aparece una versión anterior, no continúes hasta habilitar una fuente compatible aprobada por el profesor y documentarla.

## 3. Colocar el proyecto en CentOS

El proyecto final debe quedar en `/opt/library`. Si transferiste `ejercicio02.tar.gz` a tu directorio personal:

```bash
sudo mkdir -p /opt/library
sudo tar -xzf ~/ejercicio02.tar.gz --strip-components=1 -C /opt/library
sudo useradd --system --create-home --shell /sbin/nologin library 2>/dev/null || true
sudo chown -R library:library /opt/library
cd /opt/library
```

No copies `.env`, contraseñas, tokens ni llaves dentro de una carpeta pública.

## 4. Inicializar PostgreSQL

```bash
sudo postgresql-setup --initdb
sudo systemctl enable --now postgresql
sudo systemctl status postgresql --no-pager
```

En CentOS, la administración local inicial se realiza con la cuenta del sistema `postgres`; no necesitas conocer una contraseña de PostgreSQL:

```bash
sudo -u postgres psql
```

Para salir utiliza `\quit`.

## 5. Crear `library_app` y `online_library`

El script de bootstrap se ejecuta una sola vez como administrador local:

```bash
cd /opt/library
sudo -u postgres psql -f db/00_create_database.sql
```

El script solicita una contraseña nueva para `library_app`. Esa cuenta será propietaria únicamente de `online_library`; conserva `NOSUPERUSER`, `NOCREATEDB`, `NOCREATEROLE` y `NOREPLICATION`. La aplicación nunca se conecta como `postgres`.

Verifica el resultado:

```bash
sudo -u postgres psql -c "\du library_app"
sudo -u postgres psql -c "\l online_library"
```

## 6. Permitir autenticación local de la aplicación

Localiza los archivos reales de configuración:

```bash
sudo -u postgres psql -tAc "SHOW hba_file;"
sudo -u postgres psql -tAc "SHOW config_file;"
```

Edita el `pg_hba.conf` mostrado y asegúrate de que las conexiones TCP locales utilicen SCRAM:

```text
host    online_library    library_app    127.0.0.1/32    scram-sha-256
host    online_library    library_app    ::1/128         scram-sha-256
```

Después reinicia PostgreSQL:

```bash
sudo systemctl restart postgresql
```

Prueba el usuario de aplicación:

```bash
psql -U library_app -h 127.0.0.1 -W -d online_library
```

Dentro de psql ejecuta:

```sql
SELECT current_user, current_database();
```

El resultado debe indicar `library_app` y `online_library`. Sal con `\quit`.

## 7. Crear esquema, datos y objetos PostgreSQL

Ejecuta todo como `library_app`, nunca como `postgres`:

```bash
cd /opt/library
psql -U library_app -h 127.0.0.1 -W -d online_library -f db/01_schema.sql
psql -U library_app -h 127.0.0.1 -W -d online_library -f db/02_seed_30_per_table.sql
psql -U library_app -h 127.0.0.1 -W -d online_library -f db/03_all_quieries_before_stored_procedures.sql
psql -U library_app -h 127.0.0.1 -W -d online_library -f db/04_stored_procedures.sql
psql -U library_app -h 127.0.0.1 -W -d online_library -f db/05_triggers.sql
psql -U library_app -h 127.0.0.1 -W -d online_library -f db/06_views.sql
```

Comprueba integridad:

```bash
psql -U library_app -h 127.0.0.1 -W -d online_library -f db/07_integrity_verification.sql
```

Guarda capturas censuradas de conteos, restricciones, procedimientos, triggers, vistas y pruebas negativas.

## 8. Configurar Node.js

Instala las dependencias desde el lockfile:

```bash
cd /opt/library
sudo -u library npm ci
```

Crea el archivo de entorno:

```bash
sudo -u library cp .env.example .env
sudo chmod 600 .env
sudo nano .env
```

Configura valores reales:

```env
PORT=3000
HOST=127.0.0.1
BASE_PATH=/library
NODE_ENV=production
DATABASE_URL=postgresql://library_app:CONTRASEÑA_CODIFICADA@127.0.0.1:5432/online_library
SESSION_SECRET=FRASE_ALEATORIA_DE_32_CARACTERES_O_MAS
COOKIE_SECURE=false
UPLOAD_DIR=uploads
MAX_UPLOAD_MB=5
```

`COOKIE_SECURE=false` sólo corresponde a la prueba académica por HTTP. Al configurar HTTPS debe cambiarse a `true`. Si la contraseña contiene caracteres reservados de URL (`@`, `:`, `/`, `#`, `%`), codifícalos en `DATABASE_URL`.

Prepara imágenes:

```bash
sudo mkdir -p /opt/library/uploads
sudo chown -R library:library /opt/library/uploads
sudo chmod 750 /opt/library/uploads
```

## 9. Probar Node directamente en localhost

```bash
cd /opt/library
sudo -u library npm start
```

Desde otra sesión SSH:

```bash
curl -I http://127.0.0.1:3000/library/login
```

La aplicación no debe escuchar en la IP pública. Detén la prueba con `Ctrl+C`.

Administrador sintético:

```text
Correo: usuario1@example.test
Contraseña: Password123!
```

## 10. Instalar el servicio systemd

```bash
sudo cp deploy/library.service /etc/systemd/system/library.service
sudo systemctl daemon-reload
sudo systemctl enable --now library
sudo systemctl status library --no-pager
sudo journalctl -u library -n 50 --no-pager
```

## 11. Configurar NGINX y SELinux

```bash
sudo cp deploy/nginx-library.conf /etc/nginx/conf.d/library.conf
sudo setsebool -P httpd_can_network_connect 1
sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx
```

Prueba desde CentOS:

```bash
curl -I http://127.0.0.1/library/login
```

Después abre:

```text
http://IP_PUBLICA/library/login
```

El puerto `3000` no debe abrirse en Google Cloud ni en el firewall del sistema.

## 12. Publicar evidencias

La carpeta `evidence-site/` contiene el reporte navegable. Antes de publicarlo:

1. Sustituye nombre, matrícula, grupo y fecha.
2. Agrega capturas reales y explicadas en `evidence-site/evidencias/`.
3. Copia el contenido a `~/html/ejercicio02/` en `ubiquitous.udem.edu`.
4. Verifica enlaces y descarga en una ventana incógnita.
5. Confirma que no publicaste `.env`, llaves, cookies, tokens o contraseñas.

URL final esperada:

```text
https://ubiquitous.udem.edu/~iac-MATRICULA/ejercicio02/
```

## Documentación relacionada

- `docs/REQUIREMENTS.md`
- `docs/NORMALIZATION_4FN.md` y `docs/NORMALIZATION_4FN.xlsx`
- `docs/ENGINEERING_DECISIONS.md`
- `docs/GCP_COMMANDS.md`
- `docs/DEPLOYMENT_CENTOS_NGINX.md`
- `docs/SECURITY_REVIEW.md`
- `docs/TEST_PLAN.md` y `docs/TEST_PLAN.xlsx`
