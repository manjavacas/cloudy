#!/bin/bash

get_repo_name_from_url() {
  local repo_url="$1"

  repo_url=${repo_url%.git}
  repo_name=$(basename "$repo_url")

  echo "$repo_name"
}

if [ "$#" -ne 8 ]; then
  error "All required arguments must be provided."
  exit 1
fi

INSTANCE_NAME="$1"
BUCKET_NAME="$2"
BUCKET_ZONE="$3"
REPO_URL="$4"
SCRIPT_PATH="$5"
DEPENDENCIES="$6"
SCRIPT_ARGS="$7"
ZONE="$8"

info() {
  local message="$1"
  echo -e "\033[32m[CLOUDY $INSTANCE_NAME] $message\033[0m" # Green
}

warn() {
  local message="$1"
  echo -e "\033[33m[CLOUDY $INSTANCE_NAME] $message\033[0m" # Yellow
}

error() {
  local message="$1"
  echo -e "\033[31m[CLOUDY $INSTANCE_NAME] Error: $message\033[0m" # Red
}

OUTPUT_FILE="output_${INSTANCE_NAME}.txt"

info "Updating and installing dependencies..."

if ! sudo apt-get update >/dev/null 2>&1; then
  error "Failed to update packages."
  exit 1
fi

if ! sudo apt-get upgrade -y >/dev/null 2>&1; then
  error "Failed to upgrade packages."
  exit 1
fi

if ! sudo apt-get install -y python3 python3-pip >/dev/null 2>&1; then
  error "Failed to configure python."
  exit 1
fi

if ! pip3 install $DEPENDENCIES; then
  error "Failed to install dependencies: $DEPENDENCIES."
  exit 1
fi

REPO_NAME=$(get_repo_name_from_url "$REPO_URL")
info "Cloning repository $REPO_NAME..."

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

if ! git clone "$REPO_URL" >/dev/null 2>&1; then
  error "Failed to clone repository $REPO_NAME."
  exit 1
fi

cd "$REPO_NAME" || {
  error "Directory $REPO_NAME not found"
  exit 1
}

info "Running script: python3 $SCRIPT_PATH $SCRIPT_ARGS..."

if ! python3 "$SCRIPT_PATH" $SCRIPT_ARGS >"$OUTPUT_FILE" 2>&1; then
  error "Failed to run script $SCRIPT_PATH."
  exit 1
fi

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
    exit 1
  fi

else
  error "Output file $OUTPUT_FILE not found!"
  exit 1
fi

info "Deleting instance..."
if ! gcloud compute instances delete "$INSTANCE_NAME" --zone="$ZONE" --quiet >/dev/null 2>&1; then
  echo "Failed to delete instance $INSTANCE_NAME."
fi
