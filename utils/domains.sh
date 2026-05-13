#!/bin/bash
#
# utils/domains.sh
#
# Reads domains.json and prints each domain on its own line.
# Source this file after logger.sh and .env are already loaded.
#
# Usage:
#   source utils/domains.sh
#   read_domains        # prints each domain line by line
#   domains_array       # populates global $DOMAINS array

function read_domains() {
  local file="${MATE_DOMAINS_FILE:-domains.json}"

  if ! [[ -f "$file" ]]; then
    log_err "The file '$file' does not exist."
    log_info "Please run './mate.sh generate-domains-file' command first."
    exit 1
  fi

  if command -v jq &>/dev/null; then
    jq -r '.[]' "$file"
    return
  fi

  if command -v python3 &>/dev/null; then
    python3 -c "import json; [print(d) for d in json.load(open('$file'))]"
    return
  fi

  # Basic fallback — works for single-line JSON arrays without spaces in values.
  log_warn "jq and python3 not found. Using basic JSON parser."
  local content
  content=$(tr -d '[:space:]' < "$file")
  content="${content#[}"
  content="${content%]}"
  echo "$content" | tr ',' '\n' | tr -d '"'
}

function domains_array() {
  mapfile -t DOMAINS < <(read_domains)
}
