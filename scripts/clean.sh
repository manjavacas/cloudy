#!/bin/bash

info() {
  local message="$1"
  echo -e "\033[34m[CLOUDY] $message\033[0m"
}

warn() {
  local message="$1"
  echo -e "\033[33m[CLOUDY] $message\033[0m"
}

CONFIG_FILE="config.json"

ZONE=$(jq -r '.ZONE' $CONFIG_FILE)

# Delete VM instances
INSTANCES=$(gcloud compute instances list --format="value(name)" --filter="zone:($ZONE)" 2>/dev/null)

if [ -z "$INSTANCES" ]; then
  warn "No VM instances to delete."
else
  info "Deleting VM instances..."
  for INSTANCE in $INSTANCES; do
    info "Deleting instance: $INSTANCE..."
    gcloud compute instances delete "$INSTANCE" --zone="$ZONE" --quiet
  done
  info "All VM instances have been deleted."
fi

# Delete buckets
BUCKETS=$(gsutil ls)

if [ -z "$BUCKETS" ]; then
  warn "No GCS buckets to delete."
else
  info "Deleting GCS buckets..."
  for BUCKET in $BUCKETS; do
    info "Deleting bucket: $BUCKET..."
    gsutil rm -r "$BUCKET"
  done
  info "All GCS buckets have been deleted."
fi

info "Deletion process completed."
