#!/bin/bash

info() {
    echo -e "\033[34m$@\033[0m"
}

CONFIG_FILE="config.json"

N_VMS=$(jq -r '.N_VMS' $CONFIG_FILE)
INSTANCE_NAME_BASE=$(jq -r '.INSTANCE_NAME_BASE' $CONFIG_FILE)
MACHINE_TYPE=$(jq -r '.MACHINE_TYPE' $CONFIG_FILE)
ZONE=$(jq -r '.ZONE' $CONFIG_FILE)
IMAGE_FAMILY=$(jq -r '.IMAGE_FAMILY' $CONFIG_FILE)
IMAGE_PROJECT=$(jq -r '.IMAGE_PROJECT' $CONFIG_FILE)
BUCKET_NAME=$(jq -r '.BUCKET_NAME' $CONFIG_FILE)
SERVICE_ACCOUNT=$(jq -r '.SERVICE_ACCOUNT' $CONFIG_FILE)
SETUP_SCRIPT=$(jq -r '.SETUP_SCRIPT' $CONFIG_FILE)
BUCKET_ZONE=$(jq -r '.BUCKET_ZONE' $CONFIG_FILE)
REPO_NAME=$(jq -r '.REPO_NAME' $CONFIG_FILE)
REPO_URL=$(jq -r '.REPO_URL' $CONFIG_FILE)
SCRIPT_PATH=$(jq -r '.SCRIPT_PATH' $CONFIG_FILE)
DEPENDENCIES=$(jq -r '.DEPENDENCIES' $CONFIG_FILE)

for ((i = 1; i <= N_VMS; i++)); do
    INSTANCE_NAME="$INSTANCE_NAME_BASE-$i"

    info "[CLOUDY] Creando instancia: $INSTANCE_NAME..."
    gcloud compute instances create "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --machine-type="$MACHINE_TYPE" \
        --image-family="$IMAGE_FAMILY" \
        --image-project="$IMAGE_PROJECT" \
        --service-account="$SERVICE_ACCOUNT" \
        --scopes https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/devstorage.full_control

    while ! gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --command="info VM preparada" 2>/dev/null; do
        info "[CLOUDY] Esperando a que el servicio SSH esté disponible..."
        sleep 10
    done

    info "[CLOUDY] Copiando el script de setup a la instancia..."
    gcloud compute scp scripts/$SETUP_SCRIPT "$INSTANCE_NAME:~/" --zone="$ZONE"

    info "[CLOUDY] Ejecutando el script de setup en la instancia..."
    gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --command="chmod +x ~/$SETUP_SCRIPT && ~/$SETUP_SCRIPT '$INSTANCE_NAME' '$BUCKET_NAME' '$BUCKET_ZONE' '$REPO_NAME' '$REPO_URL' '$SCRIPT_PATH' '$DEPENDENCIES'"

    info "[CLOUDY] Fin del proceso $INSTANCE_NAME."
done
