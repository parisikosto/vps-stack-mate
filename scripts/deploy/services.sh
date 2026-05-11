#!/bin/bash
#
# scripts/deploy/services.sh
#
# Starts the Docker Compose stack (nginx + certbot).
# Run via: ./mate.sh deploy-services

set -euo pipefail

source utils/logger.sh
source utils/guards.sh

guard_require_root
guard_require_docker
guard_require_env

logger CMD "Run 'deploy-services' command"

docker compose up -d

log_ok "Services deployed successfully."
