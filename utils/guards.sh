#!/bin/bash
#
# utils/guards.sh
#
# Pre-flight checks. Source this file and call the guards you need
# at the top of a script before it does any real work.
#
# Usage:
#   source utils/guards.sh
#   guard_require_root

# ─── Repo root guard ──────────────────────────────────────────────────────────
#
# All scripts rely on relative paths (utils/, .env, nginx/, etc.).
# This guard ensures the working directory is the repo root.
# mate.sh always cd's to its own directory before calling scripts,
# so this guard mainly protects against running scripts directly.
#
function guard_require_root() {
  if [[ ! -f "mate.sh" ]]; then
    log_err "Must be run from the vps-stack-mate repo root."
    log_info "Use './mate.sh <command>' instead of running scripts directly."
    exit 1
  fi
}
