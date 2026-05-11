#!/bin/bash
#
# scripts/generate/domains-file.sh
#
# Generates a placeholder domains.json.
# Edit the generated file and replace the placeholders with your real domains.
#
# Run via: ./mate.sh generate-domains-file

set -euo pipefail

source utils/logger.sh
source utils/guards.sh

guard_require_root
guard_require_env
source .env

# ─── Main ─────────────────────────────────────────────────────────────────────

logger CMD "Run 'generate-domains-file' command"

if [[ -f "$MATE_DOMAINS_FILE" ]]; then
  while true; do
    logger DECISION "The file '$MATE_DOMAINS_FILE' already exists. Do you want to generate a new one? (y/n): "
    read -rp "" answer
    case "$answer" in
      [Yy]*) rm "$MATE_DOMAINS_FILE"; break ;;
      [Nn]*) log_info "Keeping existing '$MATE_DOMAINS_FILE' file..."; exit 0 ;;
      *)     log_err  "Please answer 'y' or 'n'." ;;
    esac
  done
fi

echo '["example.com", "subdomain.example.com"]' > "$MATE_DOMAINS_FILE"

log_ok "The file '$MATE_DOMAINS_FILE' has been generated successfully."
