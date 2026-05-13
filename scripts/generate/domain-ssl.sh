#!/bin/bash
#
# scripts/generate/domain-ssl.sh
#
# SSL certificate provisioning for a single domain.
#
# This file only defines functions — it does NOT auto-execute.
# Source it from deploy/domains.sh, then call:
#   provision_domain_ssl "$domain"
#
# Requires: logger.sh sourced, .env sourced.

# ─── TLS parameters ───────────────────────────────────────────────────────────

function _download_tls_params() {
  local conf_dir="$CERTBOT_SERVICE_DATA_DIR/conf"
  local ssl_opts="$conf_dir/options-ssl-nginx.conf"
  local dhparam="$conf_dir/ssl-dhparams.pem"

  if [[ -f "$ssl_opts" && -f "$dhparam" ]]; then
    return 0
  fi

  logger SUB_CMD "### Downloading recommended TLS parameters..."
  mkdir -p "$conf_dir"

  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf \
    > "$ssl_opts"

  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem \
    > "$dhparam"
}

# ─── SSL provisioning ─────────────────────────────────────────────────────────

function provision_domain_ssl() {
  local domain="$1"

  # Write a temporary HTTP-only nginx config.
  # No SSL block — nginx does not need a certificate at this stage.
  # This config only serves port 80 for the ACME challenge.
  logger SUB_CMD "### Writing temporary HTTP-only nginx config for '$domain'..."
  cat > "$NGINX_SERVICE_CONF_DIR/$domain.conf" <<NGINX_CONF
server {
    listen 80;
    server_name $domain;
    server_tokens off;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
NGINX_CONF

  # Reload or start nginx with the temporary HTTP-only config.
  logger SUB_CMD "### Starting nginx..."
  if docker compose ps nginx | grep -q "running\|Running"; then
    docker compose exec nginx nginx -s reload
  else
    docker compose up --force-recreate -d nginx
  fi

  sleep 5

  # Download TLS params needed for the final SSL config.
  _download_tls_params

  # Request the real Let's Encrypt certificate.
  logger SUB_CMD "### Requesting Let's Encrypt certificate for '$domain'..."

  local email_arg staging_arg=""

  if [[ -z "${CERTBOT_LETSENCRYPT_EMAIL:-}" ]]; then
    email_arg="--register-unsafely-without-email"
  else
    email_arg="--email $CERTBOT_LETSENCRYPT_EMAIL"
  fi

  if [[ "${CERTBOT_LETSENCRYPT_STAGING:-0}" != "0" ]]; then
    staging_arg="--staging"
    log_warn "Using Let's Encrypt staging environment."
  fi

  docker compose run --rm --entrypoint \
    "certbot certonly --webroot -w /var/www/certbot \
      $staging_arg \
      $email_arg \
      -d $domain \
      --rsa-key-size $CERTBOT_LETSENCRYPT_RSA_KEY_SIZE \
      --agree-tos \
      --force-renewal" \
    certbot

  log_ok "SSL certificate issued for '$domain'."
}
