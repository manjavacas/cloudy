#!/bin/bash

if [ "$#" -ne 9 ]; then
  error "Se deben proporcionar todos los argumentos necesarios."
  exit 1
fi

MACHINE_NAME="$1"
BUCKET_NAME="$2"
BUCKET_ZONE="$3"
REPO_NAME="$4"
REPO_URL="$5"
SCRIPT_PATH="$6"
DEPENDENCIES="$7"
SCRIPT_ARGS="$8"
ZONE="$9"

info() {
  local message="$1"
  echo -e "\033[32m[CLOUDY $MACHINE_NAME] $message\033[0m" # Verde
}

warn() {
  local message="$1"
  echo -e "\033[33m[CLOUDY $MACHINE_NAME] $message\033[0m" # Amarillo
}

error() {
  local message="$1"
  echo -e "\033[31m[CLOUDY $MACHINE_NAME] Error: $message\033[0m" # Rojo
}

OUTPUT_FILE="output_${MACHINE_NAME}.txt"

info "Actualizando e instalando dependencias..."

# Redirigir stdout y stderr a /dev/null para ocultar la salida
sudo apt-get update >/dev/null 2>&1
sudo apt-get upgrade -y >/dev/null 2>&1
sudo apt-get install -y python3 python3-pip >/dev/null 2>&1

pip3 install $DEPENDENCIES >/dev/null 2>&1

info "Clonando repositorio..."

git clone "$REPO_URL" >/dev/null 2>&1
cd "$REPO_NAME"

info "Ejecutando script..."

python3 "$SCRIPT_PATH" $SCRIPT_ARGS >"$OUTPUT_FILE" 2>&1

if [ -f "$OUTPUT_FILE" ]; then

  if ! command -v gsutil &>/dev/null; then
    info "Instalando Google Cloud SDK..."
    sudo apt-get install -y google-cloud-sdk >/dev/null 2>&1
  fi

  if gsutil ls -b "gs://$BUCKET_NAME" &>/dev/null; then
    info "El bucket gs://$BUCKET_NAME existe."
  else
    warn "El bucket gs://$BUCKET_NAME NO existe. Creando bucket..."
    gsutil mb -l $BUCKET_ZONE "gs://$BUCKET_NAME/" >/dev/null 2>&1
  fi

  info "Guardando $OUTPUT_FILE en el bucket gs://$BUCKET_NAME/..."
  gsutil cp "$OUTPUT_FILE" "gs://$BUCKET_NAME/" >/dev/null 2>&1

  if [ $? -eq 0 ]; then
    info "Archivo guardado en gs://$BUCKET_NAME/$OUTPUT_FILE"
  else
    error "No se pudo guardar el archivo en Google Cloud Storage."
    exit 1
  fi

else
  error "No se encontró el archivo de salida $OUTPUT_FILE"
  exit 1
fi

info "Eliminando instancia..."
gcloud compute instances delete "$MACHINE_NAME" --zone="$ZONE" --quiet 2>&1

