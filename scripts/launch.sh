#!/bin/bash

info() {
    local message="$1"
    echo -e "\033[34m[CLOUDY] $message\033[0m"
}

warn() {
    local message="$1"
    echo -e "\033[33m[CLOUDY] $message\033[0m"
}

error() {
    local message="$1"
    echo -e "\033[31m[CLOUDY] Error: $message\033[0m"
}

get_repo_name_from_url() {
    local repo_url="$1"

    repo_url=${repo_url%.git}
    repo_name=$(basename "$repo_url")

    echo "$repo_name"
}

delete_instance() {
    warn "Deleting instance $INSTANCE_NAME..."
    if ! gcloud compute instances delete "$INSTANCE_NAME" --zone="$ZONE" --quiet >/dev/null 2>&1; then
        echo "Failed to delete instance $INSTANCE_NAME."
        exit 1
    fi
}

######################################################

CONFIG_FILE="$1"

N_VMS=$(jq -r '.N_VMS' $CONFIG_FILE)
INSTANCE_NAME=$(jq -r '.INSTANCE_NAME' $CONFIG_FILE)
MACHINE_TYPE=$(jq -r '.MACHINE_TYPE' $CONFIG_FILE)
ZONE=$(jq -r '.ZONE' $CONFIG_FILE)
IMAGE_FAMILY=$(jq -r '.IMAGE_FAMILY' $CONFIG_FILE)
IMAGE_PROJECT=$(jq -r '.IMAGE_PROJECT' $CONFIG_FILE)
BUCKET_NAME=$(jq -r '.BUCKET_NAME' $CONFIG_FILE)
SERVICE_ACCOUNT=$(jq -r '.SERVICE_ACCOUNT' $CONFIG_FILE)
SETUP_SCRIPT=$(jq -r '.SETUP_SCRIPT' $CONFIG_FILE)
BUCKET_ZONE=$(jq -r '.BUCKET_ZONE' $CONFIG_FILE)
REPO_URL=$(jq -r '.REPO_URL' $CONFIG_FILE)
SCRIPT_PATH=$(jq -r '.SCRIPT_PATH' $CONFIG_FILE)
DEPENDENCIES=$(jq -r '.DEPENDENCIES' $CONFIG_FILE)
SCRIPT_ARGS=$(jq -r '.SCRIPT_ARGS' $CONFIG_FILE)

######################################################

REPO_NAME=$(get_repo_name_from_url "$REPO_URL")

if [ ! -d "$REPO_NAME" ]; then
    info "Cloning repository $REPO_NAME..."
    if ! git clone "$REPO_URL"; then
        error "Failed to clone repository $REPO_NAME."
        exit 1
    fi
else
    info "Repository $REPO_NAME is already downloaded."
fi

######################################################

info "Creating instance: $INSTANCE_NAME..."
gcloud compute instances create "$INSTANCE_NAME" \
    --zone="$ZONE" \
    --machine-type="$MACHINE_TYPE" \
    --image-family="$IMAGE_FAMILY" \
    --image-project="$IMAGE_PROJECT" \
    --service-account="$SERVICE_ACCOUNT" \
    --scopes https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/devstorage.full_control

while ! gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --command="info Instance ready!" 2>/dev/null; do
    info "Waiting for SSH service to be available..."
    sleep 10
done

######################################################

info "Copying setup script to $INSTANCE_NAME..."
if ! gcloud compute scp "scripts/$SETUP_SCRIPT" "$INSTANCE_NAME:~/" --zone="$ZONE" >/dev/null; then
    error "Failed to copy setup script to the VM instance."
    delete_instance
    exit 1
fi

info "Copying repository to $INSTANCE_NAME..."
if ! gcloud compute scp --recurse "$REPO_NAME" "$INSTANCE_NAME:~/" --zone="$ZONE" >/dev/null; then
    error "Failed to copy repository to the VM instance."
    delete_instance
    exit 1
fi

######################################################

info "Running setup script on the VM instance..."
gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --command="chmod +x ~/$SETUP_SCRIPT && ~/$SETUP_SCRIPT '$INSTANCE_NAME' '$BUCKET_NAME' '$BUCKET_ZONE' '$REPO_NAME' '$SCRIPT_PATH' '$DEPENDENCIES' '$SCRIPT_ARGS' '$ZONE'"

######################################################

info "$INSTANCE_NAME finished."
