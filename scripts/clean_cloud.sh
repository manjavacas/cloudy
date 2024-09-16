#!/bin/bash

info() {
    echo -e "\033[34m$@\033[0m"
}

CONFIG_FILE="config.json"

ZONE=$(jq -r '.ZONE' $CONFIG_FILE)

# Eliminar instancias de VM
info "[CLOUDY] Listando instancias de VM..."
INSTANCES=$(gcloud compute instances list --format="value(name)" --zones="$ZONE")

if [ -z "$INSTANCES" ]; then
  info "[CLOUDY] No hay instancias de VM para eliminar."
else
  info "[CLOUDY] Eliminando instancias de VM..."
  for INSTANCE in $INSTANCES; do
    info "[CLOUDY] Eliminando instancia: $INSTANCE..."
    gcloud compute instances delete "$INSTANCE" --zone="$ZONE" --quiet
  done
  info "[CLOUDY] Todas las instancias de VM han sido eliminadas."
fi

# Eliminar buckets
BUCKETS=$(gsutil ls)

if [ -z "$BUCKETS" ]; then
  info "[CLOUDY] No hay buckets de GCS para eliminar."
else
  info "[CLOUDY] Eliminando buckets de GCS..."
  for BUCKET in $BUCKETS; do
    info "[CLOUDY] Eliminando bucket: $BUCKET..."
    gsutil rm -r "$BUCKET"
  done
  info "[CLOUDY] Todos los buckets de GCS han sido eliminados."
fi

info "[CLOUDY] Proceso de eliminación completado."
