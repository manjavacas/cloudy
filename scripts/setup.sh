#!/bin/bash

COLOR_CYAN="36"
COLOR_YELLOW="33"
COLOR_GREEN="32"
COLOR_RED="31"

log() {
  local message="$1"
  local color="$2"
  echo -e "\033[${color}m[CLOUDY $INSTANCE_NAME] $message\033[0m"
}

info() {
  log "$1" "$COLOR_CYAN"
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

delete_instance() {
  warn "Deleting instance $INSTANCE_NAME..."
  if ! gcloud compute instances delete "$INSTANCE_NAME" --zone="$ZONE" --quiet >/dev/null 2>&1; then
    error "Failed to delete instance $INSTANCE_NAME."
  fi
}

exit_with_error() {
  error "$1"
  delete_instance
  exit 1
}

prepare_vm_instance() {
  info "Preparing VM instance..."
  if ! sudo apt-get update -y >/dev/null 2>&1 || ! sudo apt-get upgrade -y >/dev/null 2>&1 || ! sudo apt-get install -y python3 python3-pip >/dev/null 2>&1; then
    exit_with_error "Failed to prepare the VM instance."
  fi
}

install_dependencies() {
  if [ -n "$DEPENDENCIES" ]; then
    info "Installing dependencies: $DEPENDENCIES..."
    if ! pip3 install $DEPENDENCIES >/dev/null 2>&1; then
      exit_with_error "Failed to install dependencies: $DEPENDENCIES."
    fi
  fi
}

run_script() {
  info "Running script: python3 $SCRIPT_PATH $SCRIPT_ARGS..."
  OUTPUT_FILE="output_${INSTANCE_NAME}.txt"
  if ! python3 "$SCRIPT_PATH" $SCRIPT_ARGS >"$OUTPUT_FILE" 2>&1; then
    exit_with_error "Failed to run script $SCRIPT_PATH."
  fi
}

save_output_to_bucket() {
  if [ -f "$OUTPUT_FILE" ]; then

    if ! command -v gsutil &>/dev/null; then
      info "Installing Google Cloud SDK..."
      if ! sudo apt-get install -y google-cloud-sdk >/dev/null 2>&1; then
        exit_with_error "Failed to install Google Cloud SDK."
      fi
    fi

    if ! gsutil ls -b "gs://$BUCKET_NAME" &>/dev/null; then
      warn "The bucket gs://$BUCKET_NAME does NOT exist. Creating bucket..."
      if ! gsutil mb -l "$BUCKET_ZONE" "gs://$BUCKET_NAME" >/dev/null 2>&1; then
        exit_with_error "Failed to create bucket gs://$BUCKET_NAME."
      fi
    else
      info "The bucket gs://$BUCKET_NAME already exists."
    fi

    FILE_NAME=$(basename "$OUTPUT_FILE")
    info "Saving $OUTPUT_FILE to bucket gs://$BUCKET_NAME/..."
    if ! gsutil cp "$OUTPUT_FILE" "gs://$BUCKET_NAME/$FILE_NAME" >/dev/null 2>&1; then
      exit_with_error "Failed to save the file in Google Cloud Storage."
    fi

    info "File saved to gs://$BUCKET_NAME/$FILE_NAME"
  else
    exit_with_error "Output file $OUTPUT_FILE not found."
  fi
}

main() {
  if [ "$#" -ne 8 ]; then
    exit_with_error "All required arguments must be provided."
  fi

  INSTANCE_NAME="$1"
  BUCKET_NAME="$2"
  BUCKET_ZONE="$3"
  REPO_NAME="$4"
  SCRIPT_PATH="$5"
  DEPENDENCIES="$6"
  SCRIPT_ARGS="$7"
  ZONE="$8"

  prepare_vm_instance
  cd "$REPO_NAME" || exit_with_error "Directory $REPO_NAME not found"
  install_dependencies
  run_script
  save_output_to_bucket

  check "Job completed!"
  delete_instance
}

main "$@"
