# Infraestructura GCP con SDK CLI

> Sustituye `TU_PROYECTO`, revisa facturación/cuotas y no pegues tokens. Región propuesta: `us-central1`, zona `us-central1-a`; cámbialas si el profesor asignó otra.

## Preparación

```bash
gcloud auth login
gcloud config set project TU_PROYECTO
gcloud services enable compute.googleapis.com
```

## Firewall y VM

```bash
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
  --tags=library-web \
  --shielded-vtpm \
  --shielded-integrity-monitoring

gcloud compute ssh library-vm --zone=us-central1-a
```

`e2-small` (2 vCPU compartidas, 2 GB) es suficiente para ejercicio y pruebas con bajo tráfico; producción real debe dimensionarse con métricas. No se abre 3000 ni 5432: Node y PostgreSQL permanecen locales. CentOS Stream 10 usa proyecto `centos-cloud` y familia `centos-stream-10`, actualmente GA según [Google Cloud OS details](https://docs.cloud.google.com/compute/docs/images/os-details).

## Evidencia reproducible

```bash
gcloud compute instances describe library-vm --zone=us-central1-a \
  --format='table(name,status,machineType.basename(),zone.basename(),networkInterfaces[0].accessConfigs[0].natIP)'
gcloud compute firewall-rules describe allow-library-web
```

Captura comandos y resultados sin tokens, claves o datos de facturación. Detén o elimina la VM al terminar para evitar cargos:

```bash
gcloud compute instances stop library-vm --zone=us-central1-a
```
