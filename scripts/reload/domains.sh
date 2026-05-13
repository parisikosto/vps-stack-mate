#!/bin/bash
#
# scripts/reload/domains.sh
#
# Rebuilds nginx/conf.d/ from domains.json and force-recreates nginx.
# Use this when you add a new domain to domains.json or change a conf file,
# without needing to re-provision SSL certificates.
#
# Run via: ./mate.sh reload-domains

set -euo pipefail

source utils/logger.sh
source utils/guards.sh
source utils/domains.sh

guard_require_root
guard_require_docker
guard_require_env
source .env
guard_require_domains_file

# ─── Main ─────────────────────────────────────────────────────────────────────

logger CMD "Run 'reload-domains' command"

domains_array

logger SUB_CMD "### Clearing '$NGINX_SERVICE_CONF_DIR' directory..."
rm -rf "$NGINX_SERVICE_CONF_DIR"
mkdir -p "$NGINX_SERVICE_CONF_DIR"

for domain in "${DOMAINS[@]}"; do
  logger CMD "================> $domain <================"

  local_conf="$NGINX_MATE_CONF_DIR/$domain.conf"

  if [[ -f "$local_conf" ]]; then
    logger SUB_CMD "### Copying custom nginx conf for '$domain'..."
    cp "$local_conf" "$NGINX_SERVICE_CONF_DIR/$domain.conf"
  else
    logger INFO "No custom conf found for '$domain'. Using default template..."
    sed "s/domain_placeholder/$domain/g" "$NGINX_MATE_CONF_DIR/default.conf" \
      > "$NGINX_SERVICE_CONF_DIR/$domain.conf"
  fi

  log_info "Finished copying '$domain' nginx conf file."
done

logger SUB_CMD "### Restarting nginx..."
docker compose up --force-recreate -d nginx

log_ok "The 'reload-domains' command has been completed successfully."
