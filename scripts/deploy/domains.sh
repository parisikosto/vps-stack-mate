#!/bin/bash
#
# scripts/deploy/domains.sh
#
# Provisions SSL certificates and writes nginx configs for every domain
# listed in domains.json.
#
# Run via: ./mate.sh deploy-domains

set -euo pipefail

source utils/logger.sh
source utils/guards.sh
source utils/domains.sh
source scripts/generate/domain-ssl.sh

guard_require_root
guard_require_docker
guard_require_env
source .env
guard_require_domains_file

# ─── nginx conf.d helpers ─────────────────────────────────────────────────────

function clear_nginx_conf_dir() {
  logger SUB_CMD "### Clearing '$NGINX_SERVICE_CONF_DIR' directory..."
  rm -rf "$NGINX_SERVICE_CONF_DIR"
  mkdir -p "$NGINX_SERVICE_CONF_DIR"
}

function copy_nginx_conf() {
  local domain="$1"
  local src="$NGINX_MATE_CONF_DIR/$domain.conf"
  local dst="$NGINX_SERVICE_CONF_DIR/$domain.conf"

  if [[ -f "$src" ]]; then
    logger SUB_CMD "### Copying custom nginx conf for '$domain'..."
    cp "$src" "$dst"
  else
    logger INFO "No custom conf found for '$domain'. Using default template..."
    sed "s/domain_placeholder/$domain/g" "$NGINX_MATE_CONF_DIR/default.conf" > "$dst"
  fi
}

# ─── SSL setup ────────────────────────────────────────────────────────────────

function setup_ssl() {
  local domain="$1"
  local live_dir="$CERTBOT_SERVICE_DATA_DIR/conf/live/$domain"
  local renewal_conf="$CERTBOT_SERVICE_DATA_DIR/conf/renewal/$domain.conf"

  if [[ -d "$live_dir" && -f "$renewal_conf" ]]; then
    logger INFO "Certificate already exists for '$domain'."
    logger DECISION "Do you want to regenerate it? [y/N]: "
    read -rp "" regen
    if [[ "$regen" =~ ^[Yy]$ ]]; then
      copy_nginx_conf "$domain"
      provision_domain_ssl "$domain"
    fi
  else
    copy_nginx_conf "$domain"
    provision_domain_ssl "$domain"
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

logger CMD "Run 'deploy-domains' command"

domains_array

logger SUB_CMD "### Setting up SSL certificates..."
for domain in "${DOMAINS[@]}"; do
  logger CMD "================> $domain <================"
  setup_ssl "$domain"
done

logger SUB_CMD "### Writing nginx conf.d..."
clear_nginx_conf_dir
for domain in "${DOMAINS[@]}"; do
  copy_nginx_conf "$domain"
  log_info "Finished copying '$domain' nginx conf file."
done

logger SUB_CMD "### Restarting nginx..."
docker compose up --force-recreate -d nginx

log_ok "The 'deploy-domains' command has been completed successfully."
