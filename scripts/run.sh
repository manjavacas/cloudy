#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "[CLOUDEXEC] Error: no se introdujo el nombre de la VM y el bucket de GCS como argumentos."
  exit 1
fi

MACHINE_NAME="$1"
BUCKET_NAME="$2"

REPO_NAME="cloudexec"
REPO_URL="https://github.com/manjavacas/$REPO_NAME.git"

SCRIPT_PATH="test/foo.py"
OUTPUT_FILE="output_${MACHINE_NAME}.txt"

DEPENDENCIES="numpy pandas"

############################################################

echo "[CLOUDEXEC] Actualizando e instalando dependencias..."

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y python3 python3-pip

pip3 install $DEPENDENCIES

############################################################

echo "[CLOUDEXEC] Clonando repositorio..."

git clone $REPO_URL
cd "$REPO_NAME"

############################################################

echo "[CLOUDEXEC] Ejecutando script..."

python3 "$SCRIPT_PATH" "$MACHINE_NAME" >"$OUTPUT_FILE"

############################################################

echo "[CLOUDEXEC] Guardando $OUTPUT_FILE en el bucket gs://$BUCKET_NAME/..."

if [ -f "$OUTPUT_FILE" ]; then
  # Instalar Google Cloud SDK si es necesario
  if ! command -v gsutil &>/dev/null; then
    echo "[CLOUDEXEC] Instalando Google Cloud SDK..."
    sudo apt-get install -y google-cloud-sdk
  fi

  # Verificar si el bucket ya existe
  if gsutil ls -b "gs://$BUCKET_NAME" &>/dev/null; then
    echo "[CLOUDEXEC] El bucket gs://$BUCKET_NAME ya existe."
  else
    echo "[CLOUDEXEC] El bucket gs://$BUCKET_NAME no existe. Creando el bucket..."
    gsutil mb -l us-central1 "gs://$BUCKET_NAME/"
  fi

  # Subir el archivo al bucket de Google Cloud Storage
  gsutil cp "$OUTPUT_FILE" "gs://$BUCKET_NAME/"

  # Verificar subida
  if [ $? -eq 0 ]; then
    echo "[CLOUDEXEC] Archivo subido a gs://$BUCKET_NAME/$OUTPUT_FILE"
  else
    echo "[CLOUDEXEC] Error al subir el archivo a Google Cloud Storage."
  fi

else
  echo "[CLOUDEXEC] Error: No se encontró el archivo de salida $OUTPUT_FILE."
fi
