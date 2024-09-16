#!/bin/bash

CONFIG_FILE="config.json"

ZONE=$(jq -r '.ZONE' $CONFIG_FILE)

# Eliminar instancias de VM
echo "[CLOUDY] Listando instancias de VM..."
INSTANCES=$(gcloud compute instances list --format="value(name)" --zones="$ZONE")

if [ -z "$INSTANCES" ]; then
  echo "[CLOUDY] No hay instancias de VM para eliminar."
else
  echo "[CLOUDY] Eliminando instancias de VM..."
  for INSTANCE in $INSTANCES; do
    echo "[CLOUDY] Eliminando instancia: $INSTANCE..."
    gcloud compute instances delete "$INSTANCE" --zone="$ZONE" --quiet
  done
  echo "[CLOUDY] Todas las instancias de VM han sido eliminadas."
fi

# Eliminar buckets
BUCKETS=$(gsutil ls)

if [ -z "$BUCKETS" ]; then
  echo "[CLOUDY] No hay buckets de GCS para eliminar."
else
  echo "[CLOUDY] Eliminando buckets de GCS..."
  for BUCKET in $BUCKETS; do
    echo "[CLOUDY] Eliminando bucket: $BUCKET..."
    gsutil rm -r "$BUCKET"
  done
  echo "[CLOUDY] Todos los buckets de GCS han sido eliminados."
fi

echo "[CLOUDY] Proceso de eliminación completado."
