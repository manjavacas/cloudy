#!/bin/bash

info() {
  local message="$1"
  echo -e "\033[34m[CLOUDY] $message\033[0m"
}

warn() {
  local message="$1"
  echo -e "\033[33m[CLOUDY] $message\033[0m"
}

CONFIG_FILE="config.json"

ZONE=$(jq -r '.ZONE' $CONFIG_FILE)

# Eliminar instancias de VM
INSTANCES=$(gcloud compute instances list --format="value(name)" --filter="zone:($ZONE)" 2>/dev/null)

if [ -z "$INSTANCES" ]; then
  warn "No hay instancias de VM para eliminar."
else
  info "Eliminando instancias de VM..."
  for INSTANCE in $INSTANCES; do
    info "Eliminando instancia: $INSTANCE..."
    gcloud compute instances delete "$INSTANCE" --zone="$ZONE" --quiet
  done
  info "Todas las instancias de VM han sido eliminadas."
fi

# Eliminar buckets
BUCKETS=$(gsutil ls)

if [ -z "$BUCKETS" ]; then
  warn "No hay buckets de GCS para eliminar."
else
  info "Eliminando buckets de GCS..."
  for BUCKET in $BUCKETS; do
    info "Eliminando bucket: $BUCKET..."
    gsutil rm -r "$BUCKET"
  done
  info "Todos los buckets de GCS han sido eliminados."
fi

info "Proceso de eliminación completado."
