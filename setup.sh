#!/bin/bash

# Verificar si se proporcionaron los argumentos necesarios
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "[CLOUDEXEC] Error: no se introdujo el nombre de la VM y el bucket de GCS como argumentos."
  exit 1
fi

MACHINE_NAME="$1"
BUCKET_NAME="$2"

# Leer configuración desde el archivo JSON
CONFIG_FILE="config.json"

BUCKET_ZONE=$(jq -r '.BUCKET_ZONE' $CONFIG_FILE)
REPO_NAME=$(jq -r '.REPO_NAME' $CONFIG_FILE)
REPO_URL=$(jq -r '.REPO_URL' $CONFIG_FILE)
SCRIPT_PATH=$(jq -r '.SCRIPT_PATH' $CONFIG_FILE)
DEPENDENCIES=$(jq -r '.DEPENDENCIES' $CONFIG_FILE)

OUTPUT_FILE="output_${MACHINE_NAME}.txt"

############################################################

echo "[CLOUDEXEC] Actualizando e instalando dependencias..."

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y python3 python3-pip

pip3 install $DEPENDENCIES

############################################################

echo "[CLOUDEXEC] Clonando repositorio..."

git clone "$REPO_URL"
cd "$REPO_NAME"

############################################################

echo "[CLOUDEXEC] Ejecutando script..."

python3 "$SCRIPT_PATH" "$MACHINE_NAME" >"$OUTPUT_FILE"

############################################################

if [ -f "$OUTPUT_FILE" ]; then

  if ! command -v gsutil &>/dev/null; then
    echo "[CLOUDEXEC] Instalando Google Cloud SDK..."
    sudo apt-get install -y google-cloud-sdk
  fi

  ############################################################

  if gsutil ls -b "gs://$BUCKET_NAME" &>/dev/null; then
    echo "[CLOUDEXEC] El bucket gs://$BUCKET_NAME existe."
  else
    echo "[CLOUDEXEC] El bucket gs://$BUCKET_NAME NO existe. Creando bucket..."
    gsutil mb -l $BUCKET_ZONE "gs://$BUCKET_NAME/"
  fi

  ############################################################

  echo "[CLOUDEXEC] Guardando $OUTPUT_FILE en el bucket gs://$BUCKET_NAME/..."
  gsutil cp "$OUTPUT_FILE" "gs://$BUCKET_NAME/"

  ############################################################

  if [ $? -eq 0 ]; then
    echo "[CLOUDEXEC] Archivo subido a gs://$BUCKET_NAME/$OUTPUT_FILE"
  else
    echo "[CLOUDEXEC] Error: no se pudo subir el archivo a Google Cloud Storage."
  fi

else
  echo "[CLOUDEXEC] Error: No se encontró el archivo de salida $OUTPUT_FILE."
fi
