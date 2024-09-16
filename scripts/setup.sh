#!/bin/bash

info() {
    echo -e "\033[34m$@\033[0m"
}

if [ "$#" -ne 7 ]; then
  info "[CLOUDY $MACHINE_NAME] Error: se deben proporcionar todos los argumentos necesarios."
  exit 1
fi

MACHINE_NAME="$1"
BUCKET_NAME="$2"
BUCKET_ZONE="$3"
REPO_NAME="$4"
REPO_URL="$5"
SCRIPT_PATH="$6"
DEPENDENCIES="$7"

OUTPUT_FILE="output_${MACHINE_NAME}.txt"

info "[CLOUDY $MACHINE_NAME] Actualizando e instalando dependencias..."

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y python3 python3-pip

pip3 install $DEPENDENCIES

info "[CLOUDY $MACHINE_NAME] Clonando repositorio..."

git clone "$REPO_URL"
cd "$REPO_NAME"

info "[CLOUDY $MACHINE_NAME] Ejecutando script..."

python3 "$SCRIPT_PATH" "$MACHINE_NAME" >"$OUTPUT_FILE"

if [ -f "$OUTPUT_FILE" ]; then

  if ! command -v gsutil &>/dev/null; then
    info "[CLOUDY] Instalando Google Cloud SDK..."
    sudo apt-get install -y google-cloud-sdk
  fi

  if gsutil ls -b "gs://$BUCKET_NAME" &>/dev/null; then
    info "[CLOUDY $MACHINE_NAME] El bucket gs://$BUCKET_NAME existe."
  else
    info "[CLOUDY $MACHINE_NAME] El bucket gs://$BUCKET_NAME NO existe. Creando bucket..."
    gsutil mb -l $BUCKET_ZONE "gs://$BUCKET_NAME/"
  fi

  info "[CLOUDY $MACHINE_NAME] Guardando $OUTPUT_FILE en el bucket gs://$BUCKET_NAME/..."
  gsutil cp "$OUTPUT_FILE" "gs://$BUCKET_NAME/"

  if [ $? -eq 0 ]; then
    info "[CLOUDY $MACHINE_NAME] Archivo subido a gs://$BUCKET_NAME/$OUTPUT_FILE"
  else
    info "[CLOUDY $MACHINE_NAME] Error: no se pudo subir el archivo a Google Cloud Storage."
    exit 1
  fi

else
  info "[CLOUDY $MACHINE_NAME] Error: No se encontró el archivo de salida $OUTPUT_FILE."
  exit 1
fi
