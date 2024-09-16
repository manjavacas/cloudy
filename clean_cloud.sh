#!/bin/bash

CONFIG_FILE="config.json"

ZONE=$(jq -r '.ZONE' $CONFIG_FILE)

# Eliminar instancias de VM
echo "[CLOUDEXEC] Listando instancias de VM..."
INSTANCES=$(gcloud compute instances list --format="value(name)" --zones="$ZONE")

if [ -z "$INSTANCES" ]; then
  echo "[CLOUDEXEC] No hay instancias de VM para eliminar."
else
  echo "[CLOUDEXEC] Eliminando instancias de VM..."
  for INSTANCE in $INSTANCES; do
    echo "[CLOUDEXEC] Eliminando instancia: $INSTANCE..."
    gcloud compute instances delete "$INSTANCE" --zone="$ZONE" --quiet
  done
  echo "[CLOUDEXEC] Todas las instancias de VM han sido eliminadas."
fi

# Eliminar buckets
echo "[CLOUDEXEC] Listando buckets de GCS..."
BUCKETS=$(gsutil ls)

if [ -z "$BUCKETS" ]; then
  echo "[CLOUDEXEC] No hay buckets de GCS para eliminar."
else
  echo "[CLOUDEXEC] Eliminando buckets de GCS..."
  for BUCKET in $BUCKETS; do
    echo "[CLOUDEXEC] Eliminando bucket: $BUCKET..."
    gsutil rm -r "$BUCKET"
  done
  echo "[CLOUDEXEC] Todos los buckets de GCS han sido eliminados."
fi

echo "[CLOUDEXEC] Proceso de eliminación completado."
