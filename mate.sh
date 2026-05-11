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

  generate-env-file   Generate .env

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

  *)
    log_err "Unknown command: '$CMD'"
    echo
    echo "$USAGE"
    exit 1
    ;;
esac
