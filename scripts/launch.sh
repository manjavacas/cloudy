#!/bin/bash

set -e

COLOR_BLUE="34"
COLOR_YELLOW="33"
COLOR_GREEN="32"
COLOR_RED="31"

MAX_ATTEMPTS=10
SLEEP_INTERVAL=10

log() {
    local message="$1"
    local color="$2"
    echo -e "\033[${color}m[CLOUDY] $message\033[0m"
}

info() {
    log "$1" "$COLOR_BLUE"
}

warn() {
    log "$1" "$COLOR_YELLOW"
}

check() {
    log "$1" "$COLOR_GREEN"
}

error() {
    log "ERROR: $1" "$COLOR_RED"
}

exit_with_error() {
    error "$1"
    delete_instance
    exit 1
}

get_repo_name_from_url() {
    basename "${1%.git}"
}

delete_instance() {
    warn "Deleting instance $INSTANCE_NAME..."
    if ! gcloud compute instances delete "$INSTANCE_NAME" --zone="$ZONE" --quiet >/dev/null 2>&1; then
        exit_with_error "Failed to delete instance $INSTANCE_NAME."
    fi
}

load_config() {
    if [ -z "$INSTANCE_NAME" ]; then
        local config_file="$1"
        if [ ! -f "$config_file" ]; then
            exit_with_error "Configuration file $config_file not found."
        fi

        N_VMS=$(jq -r '.N_VMS' "$config_file")
        INSTANCE_NAME=$(jq -r '.INSTANCE_NAME' "$config_file")
        MACHINE_TYPE=$(jq -r '.MACHINE_TYPE' "$config_file")
        ZONE=$(jq -r '.ZONE' "$config_file")
        IMAGE_FAMILY=$(jq -r '.IMAGE_FAMILY' "$config_file")
        IMAGE_PROJECT=$(jq -r '.IMAGE_PROJECT' "$config_file")
        BUCKET_NAME=$(jq -r '.BUCKET_NAME' "$config_file")
        SERVICE_ACCOUNT=$(jq -r '.SERVICE_ACCOUNT' "$config_file")
        SETUP_SCRIPT=$(jq -r '.SETUP_SCRIPT' "$config_file")
        BUCKET_ZONE=$(jq -r '.BUCKET_ZONE' "$config_file")
        REPO_URL=$(jq -r '.REPO_URL' "$config_file")
        SCRIPT_PATH=$(jq -r '.SCRIPT_PATH' "$config_file")
        DEPENDENCIES=$(jq -r '.DEPENDENCIES' "$config_file")
        SCRIPT_ARGS=$(jq -r '.SCRIPT_ARGS' "$config_file")
    fi
}

clone_repository() {
    local repo_url="$1"
    local repo_name="$2"
    if [ ! -d "$repo_name" ]; then
        info "Cloning repository $repo_name..."
        if ! git clone "$repo_url"; then
            exit_with_error "Failed to clone repository $repo_name."
        fi
    else
        info "Repository $repo_name is already downloaded."
    fi
}

create_instance() {
    info "Creating VM instance: $INSTANCE_NAME..."
    if ! gcloud compute instances create "$INSTANCE_NAME" \
        --zone="$ZONE" \
        --machine-type="$MACHINE_TYPE" \
        --image-family="$IMAGE_FAMILY" \
        --image-project="$IMAGE_PROJECT" \
        --service-account="$SERVICE_ACCOUNT" \
        --scopes https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/devstorage.full_control; then
        exit_with_error "Failed to create VM instance $INSTANCE_NAME."
    fi
}

wait_for_ssh() {
    local attempts=0
    while ! gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --command="info Instance ready!" 2>/dev/null; do
        info "Waiting for SSH service to be available..."
        attempts=$((attempts + 1))
        if [ "$attempts" -ge "$MAX_ATTEMPTS" ]; then
            exit_with_error "SSH service did not become available after $MAX_ATTEMPTS attempts."
        fi
        sleep "$SLEEP_INTERVAL"
    done
}

copy_files_to_instance() {
    info "Copying setup script to $INSTANCE_NAME..."
    if ! gcloud compute scp "scripts/$SETUP_SCRIPT" "$INSTANCE_NAME:~/" --zone="$ZONE" >/dev/null; then
        exit_with_error "Failed to copy setup script to the VM instance."
    fi

    info "Copying repository to $INSTANCE_NAME..."
    if ! gcloud compute scp --recurse "$REPO_NAME" "$INSTANCE_NAME:~/" --zone="$ZONE" >/dev/null; then
        exit_with_error "Failed to copy repository to the VM instance."
    fi
}

run_setup_script() {
    info "Running setup script on the VM instance..."
    gcloud compute ssh "$INSTANCE_NAME" --zone="$ZONE" --command="chmod +x ~/$SETUP_SCRIPT && ~/$SETUP_SCRIPT '$INSTANCE_NAME' '$BUCKET_NAME' '$BUCKET_ZONE' '$REPO_NAME' '$SCRIPT_PATH' '$DEPENDENCIES' '$SCRIPT_ARGS' '$ZONE'"
}

main() {
    CONFIG_FILE="$1"
    if [ -z "$CONFIG_FILE" ]; then
        exit_with_error "Configuration file not provided."
    fi

    load_config "$CONFIG_FILE"
    REPO_NAME=$(get_repo_name_from_url "$REPO_URL")

    clone_repository "$REPO_URL" "$REPO_NAME"
    create_instance
    wait_for_ssh
    copy_files_to_instance
    check "$INSTANCE_NAME is ready."
    run_setup_script

}

main "$@"
