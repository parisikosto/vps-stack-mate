#!/bin/bash
#
# mate.sh — vps-stack-mate CLI
#
# The single entry point for all operations.
# Always run from the repo root: ./mate.sh <command>

set -euo pipefail

# Always execute from the repo root, regardless of where the caller is.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

source utils/logger.sh

# ─── Help ─────────────────────────────────────────────────────────────────────
USAGE="$(cat <<'EOF'
Usage: ./mate.sh <command>

  generate-env-file       Generate .env
  generate-domains-file   Generate a placeholder domains.json
  generate-config-files   Run both generate commands above

  deploy-services         Start the Docker Compose stack
  deploy-domains          Provision SSL certs and write nginx configs
  deploy-stack            Full deploy: services + domains

  reload-domains          Rebuild nginx configs and restart nginx
  reload-service          Pull and recreate a single service
  reload-stack            Redeploy all services and reload domains

  clean-stack             Remove certbot/, nginx/conf.d/, .env, domains.json

Options:
  -h, --help    Show this help
EOF
)"

# ─── Dispatch ─────────────────────────────────────────────────────────────────
CMD="${1:-}"

case "$CMD" in
  -h|--help|"")
    echo "$USAGE"
    exit 0
    ;;

  generate-env-file)
    bash scripts/generate/env-file.sh "${@:2}"
    ;;

  generate-domains-file)
    bash scripts/generate/domains-file.sh "${@:2}"
    ;;

  generate-config-files)
    bash scripts/generate/env-file.sh "${@:2}"
    bash scripts/generate/domains-file.sh "${@:2}"
    ;;

  deploy-services)
    bash scripts/deploy/services.sh "${@:2}"
    ;;

  deploy-domains)
    bash scripts/deploy/domains.sh "${@:2}"
    ;;

  deploy-stack)
    bash scripts/deploy/services.sh "${@:2}"
    bash scripts/deploy/domains.sh "${@:2}"
    ;;

  reload-domains)
    bash scripts/reload/domains.sh "${@:2}"
    ;;

  reload-service)
    bash scripts/reload/service.sh "${@:2}"
    ;;

  reload-stack)
    bash scripts/deploy/services.sh "${@:2}"
    bash scripts/reload/domains.sh "${@:2}"
    ;;

  clean-stack)
    rm -rf certbot nginx/conf.d .env domains.json
    log_ok "Stack cleaned."
    ;;

  *)
    log_err "Unknown command: '$CMD'"
    echo
    echo "$USAGE"
    exit 1
    ;;
esac
