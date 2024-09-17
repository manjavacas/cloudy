#!/bin/bash

if [ "$#" -ne 8 ]; then
  error "All required arguments must be provided."
  exit 1
fi

INSTANCE_NAME="$1"
BUCKET_NAME="$2"
BUCKET_ZONE="$3"
REPO_NAME="$4"
SCRIPT_PATH="$5"
DEPENDENCIES="$6"
SCRIPT_ARGS="$7"
ZONE="$8"

######################################################

info() {
  local message="$1"
  echo -e "\033[32m[CLOUDY $INSTANCE_NAME] $message\033[0m"
}

warn() {
  local message="$1"
  echo -e "\033[33m[CLOUDY $INSTANCE_NAME] $message\033[0m"
}

error() {
  local message="$1"
  echo -e "\033[31m[CLOUDY $INSTANCE_NAME] Error: $message\033[0m"
}

delete_instance() {
  warn "Deleting instance $INSTANCE_NAME..."
  if ! gcloud compute instances delete "$INSTANCE_NAME" --zone="$ZONE" --quiet >/dev/null 2>&1; then
    echo "Failed to delete instance $INSTANCE_NAME."
    exit 1
  fi
}

######################################################

info "Preparing VM instance..."

if ! sudo apt-get update >/dev/null 2>&1; then
  error "Failed to update packages."
  delete_instance
  exit 1
fi

if ! sudo apt-get upgrade -y >/dev/null 2>&1; then
  error "Failed to upgrade packages."
  delete_instance
  exit 1
fi

if ! sudo apt-get install -y python3 python3-pip >/dev/null 2>&1; then
  error "Failed to configure python."
  delete_instance
  exit 1
fi

######################################################

cd "$REPO_NAME" || {
  error "Directory $REPO_NAME not found"
  delete_instance
  exit 1
}

######################################################

if [ -n "$DEPENDENCIES" ]; then
  info "Installing dependencies: $DEPENDENCIES..."
  if ! pip3 install $DEPENDENCIES; then
    error "Failed to install dependencies: $DEPENDENCIES."
    delete_instance
    exit 1
  fi
fi

######################################################

info "Running script: python3 $SCRIPT_PATH $SCRIPT_ARGS..."

OUTPUT_FILE="output_${INSTANCE_NAME}.txt"

if ! python3 "$SCRIPT_PATH" $SCRIPT_ARGS >"$OUTPUT_FILE"; then
  error "Failed to run script $SCRIPT_PATH."
  delete_instance
  exit 1
fi

######################################################

if [ -f "$OUTPUT_FILE" ]; then

  if ! command -v gsutil &>/dev/null; then
    info "Installing Google Cloud SDK..."
    sudo apt-get install -y google-cloud-sdk >/dev/null 2>&1
  fi

  if gsutil ls -b "gs://$BUCKET_NAME" &>/dev/null; then
    info "The bucket gs://$BUCKET_NAME already exists."
  else
    warn "The bucket gs://$BUCKET_NAME does NOT exist. Creating bucket..."
    gsutil mb -l $BUCKET_ZONE "gs://$BUCKET_NAME/" >/dev/null 2>&1
  fi

  info "Saving $OUTPUT_FILE to bucket gs://$BUCKET_NAME/..."
  gsutil cp "$OUTPUT_FILE" "gs://$BUCKET_NAME/" >/dev/null 2>&1

  if [ $? -eq 0 ]; then
    info "File saved to gs://$BUCKET_NAME/$OUTPUT_FILE"
  else
    error "Failed to save the file in Google Cloud Storage."
    delete_instance
    exit 1
  fi

else
  error "Output file $OUTPUT_FILE not found."
  delete_instance
  exit 1
fi

######################################################

info "Work completed!"
delete_instance
