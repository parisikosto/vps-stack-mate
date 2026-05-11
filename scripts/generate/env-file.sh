#!/bin/bash
#
# scripts/generate/env-file.sh
#
# Generates the .env file needed by Docker Compose and all mate.sh scripts.
# Run via: ./mate.sh generate-env-file

set -euo pipefail

source utils/logger.sh
source utils/guards.sh

guard_require_root

# ─── Defaults ────────────────────────────────────────────────────────────────
MATE_DOMAINS_FILE="domains.json"
NGINX_MATE_CONF_DIR="nginx/conf"

NGINX_SERVICE_NAME="nginx-mate"
NGINX_SERVICE_CONF_DIR="nginx/conf.d"

CERTBOT_SERVICE_NAME="certbot-mate"
CERTBOT_SERVICE_DATA_DIR="certbot/data"
CERTBOT_LETSENCRYPT_RSA_KEY_SIZE=4096
CERTBOT_LETSENCRYPT_STAGING=0

# ─── Main ─────────────────────────────────────────────────────────────────────

logger CMD "Run 'generate-env-file' command"

if [[ -f ".env" ]]; then
  while true; do
    logger DECISION "The file '.env' already exists. Do you want to generate a new one? (y/n): "
    read -rp "" answer
    case "$answer" in
      [Yy]*) rm .env; break ;;
      [Nn]*) log_info "Keeping existing '.env' file..."; exit 0 ;;
      *)     log_err  "Please answer y or n." ;;
    esac
  done
fi

logger DECISION "Enter your Certbot email for Let's Encrypt notifications (leave blank to skip): "
read -rp "" CERTBOT_LETSENCRYPT_EMAIL

cat > .env <<EOF
# vps-stack-mate config variables
MATE_DOMAINS_FILE=$MATE_DOMAINS_FILE
NGINX_MATE_CONF_DIR=$NGINX_MATE_CONF_DIR

# vps-stack-mate services variables
## Nginx
NGINX_SERVICE_NAME=$NGINX_SERVICE_NAME
NGINX_SERVICE_CONF_DIR=$NGINX_SERVICE_CONF_DIR

## Certbot
CERTBOT_SERVICE_NAME=$CERTBOT_SERVICE_NAME
CERTBOT_SERVICE_DATA_DIR=$CERTBOT_SERVICE_DATA_DIR
## Define certbot letsencrypt config data
CERTBOT_LETSENCRYPT_EMAIL=$CERTBOT_LETSENCRYPT_EMAIL
CERTBOT_LETSENCRYPT_RSA_KEY_SIZE=$CERTBOT_LETSENCRYPT_RSA_KEY_SIZE
### Default 0
### Set to 1 if you're testing your setup to avoid hitting request limits
CERTBOT_LETSENCRYPT_STAGING=$CERTBOT_LETSENCRYPT_STAGING
EOF

log_ok "The file '.env' has been generated successfully."
