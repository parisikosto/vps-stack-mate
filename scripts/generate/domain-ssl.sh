#!/bin/bash
#
# scripts/generate/domain-ssl.sh
#
# SSL certificate provisioning functions for a single domain.
#
# This file only defines functions — it does NOT auto-execute.
# Source it from deploy/domains.sh, then call:
#   provision_domain_ssl "$domain"
#
# Requires: logger.sh sourced, .env sourced.

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

function provision_domain_ssl() {
  local domain="$1"

  _download_tls_params

  # Create a dummy certificate so nginx can start for the ACME challenge.
  logger SUB_CMD "### Creating dummy certificate for '$domain'..."
  mkdir -p "$CERTBOT_SERVICE_DATA_DIR/conf/live/$domain"

  docker compose run --rm --entrypoint \
    "openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
      -keyout '/etc/letsencrypt/live/$domain/privkey.pem' \
      -out    '/etc/letsencrypt/live/$domain/fullchain.pem' \
      -subj   '/CN=localhost'" \
    certbot

  # Start nginx so it can serve the ACME challenge files.
  logger SUB_CMD "### Starting nginx..."
  docker compose up --force-recreate -d nginx

  # Wait for nginx to fully initialize before certbot tries to connect.
  sleep 5

  # Remove the dummy certificate before requesting the real one.
  logger SUB_CMD "### Deleting dummy certificate for '$domain'..."
  docker compose run --rm --entrypoint \
    "rm -Rf \
      /etc/letsencrypt/live/$domain \
      /etc/letsencrypt/archive/$domain \
      /etc/letsencrypt/renewal/$domain.conf" \
    certbot

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

  logger SUB_CMD "### Reloading nginx..."
  docker compose exec nginx nginx -s reload

  log_ok "SSL certificate issued for '$domain'."
}
