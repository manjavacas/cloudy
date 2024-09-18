#!/bin/bash

COLOR_BLUE="34"
COLOR_YELLOW="33"
COLOR_GREEN="32"
COLOR_RED="31"

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
  exit 1
}

delete_instances() {
  local instances=$(gcloud compute instances list --format="value(name)" --filter="zone:($ZONE)" 2>/dev/null)

  if [ -z "$instances" ]; then
    warn "No VM instances to delete."
  else
    info "Deleting VM instances..."
    for instance in $instances; do
      info "Deleting instance: $instance..."
      if ! gcloud compute instances delete "$instance" --zone="$ZONE" --quiet >/dev/null 2>&1; then
        error "Failed to delete instance $instance."
      else
        info "Instance $instance deleted successfully."
      fi
    done
    check "All VM instances have been deleted."
  fi
}

delete_buckets() {
  local buckets=$(gsutil ls 2>/dev/null)

  if [ -z "$buckets" ]; then
    warn "No GCS buckets to delete."
  else
    info "Deleting GCS buckets..."
    for bucket in $buckets; do
      info "Deleting bucket: $bucket..."
      if ! gsutil rm -r "$bucket" >/dev/null 2>&1; then
        error "Failed to delete bucket $bucket."
      else
        info "Bucket $bucket deleted successfully."
      fi
    done
    check "All GCS buckets have been deleted."
  fi
}

load_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    exit_with_error "Configuration file $CONFIG_FILE not found."
  fi

  ZONE=$(jq -r '.ZONE' "$CONFIG_FILE")

  if [ -z "$ZONE" ]; then
    exit_with_error "ZONE value not found in the configuration file."
  fi
}

main() {
  CONFIG_FILE="config.json"

  load_config
  delete_instances
  delete_buckets

  check "Deletion process completed."
}

main "$@"
