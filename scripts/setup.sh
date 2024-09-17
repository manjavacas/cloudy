#!/bin/bash

if [ "$#" -ne 9 ]; then
  error "All required arguments must be provided."
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
  echo -e "\033[32m[CLOUDY $MACHINE_NAME] $message\033[0m" # Green
}

warn() {
  local message="$1"
  echo -e "\033[33m[CLOUDY $MACHINE_NAME] $message\033[0m" # Yellow
}

error() {
  local message="$1"
  echo -e "\033[31m[CLOUDY $MACHINE_NAME] Error: $message\033[0m" # Red
}

OUTPUT_FILE="output_${MACHINE_NAME}.txt"

info "Updating and installing dependencies..."

sudo apt-get update >/dev/null 2>&1
sudo apt-get upgrade -y >/dev/null 2>&1
sudo apt-get install -y python3 python3-pip >/dev/null 2>&1

pip3 install $DEPENDENCIES >/dev/null 2>&1

info "Cloning repository $REPO_NAME..."

git clone "$REPO_URL" >/dev/null 2>&1
cd "$REPO_NAME"

info "Running script: python3 $SCRIPT_PATH $SCRIPT_ARGS..."

python3 "$SCRIPT_PATH" $SCRIPT_ARGS >"$OUTPUT_FILE" 2>&1

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
if ! gcloud compute instances delete "$MACHINE_NAME" --zone="$ZONE" --quiet >/dev/null 2>&1; then
  echo "Failed to delete instance $MACHINE_NAME."
fi
