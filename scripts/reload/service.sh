#!/bin/bash
#
# scripts/reload/service.sh
#
# Interactively pulls the latest image and force-recreates a single service.
# Use this when you add a new service to docker-compose or need to update
# an existing container to its latest image.
#
# Run via: ./mate.sh reload-service

set -euo pipefail

source utils/logger.sh
source utils/guards.sh

guard_require_root
guard_require_docker

logger CMD "Run 'reload-service' command"

# Build the list of services from the current compose config.
mapfile -t services < <(docker compose config --services 2>/dev/null)

if [[ ${#services[@]} -eq 0 ]]; then
  log_err "No services found. Is the stack running?"
  exit 1
fi

PS3="Enter the number of the service you want to reload: "
select SERVICE_NAME in "${services[@]}"; do
  [[ -n "$SERVICE_NAME" ]] && break
  log_err "Invalid selection. Try again."
done

logger DECISION "Reloading/recreating service '$SERVICE_NAME'"

docker compose pull "$SERVICE_NAME"
docker compose up -d --force-recreate "$SERVICE_NAME"

log_ok "The service '$SERVICE_NAME' has been reloaded successfully."
