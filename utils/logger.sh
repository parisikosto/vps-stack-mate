#!/bin/bash
#
# utils/logger.sh
#
# Colored terminal output.
# Source this file at the top of every script.
#
# Usage:
#   source utils/logger.sh
#
#   logger CMD "generate-env-file"
#   logger ERROR "Something went wrong"
#   log_ok "Done."

# ─── ANSI color codes ─────────────────────────────────────────────────────────
_RESET="\033[0m"

_GRAY="\033[90m"
_GREEN="\033[32m"
_MAGENTA="\033[35m"
_RED="\033[31m"
_YELLOW="\033[93m"
_LIGHT_CYAN="\033[96m"

# ─── logger <LEVEL> "message" ─────────────────────────────────────────────────
#
#   CMD       top-level command is starting
#   SUB_CMD   a sub-step inside a command
#   DECISION  about to ask the user a question
#   SUCCESS   operation completed successfully
#   ERROR     something failed
#   WARN      not a failure, but the user should notice
#   INFO      neutral informational message
#
function logger() {
  local level="$1"
  local message="$2"
  local color

  case "$level" in
    CMD)      color="${_LIGHT_CYAN}"  ;;
    SUB_CMD)  color="${_MAGENTA}"     ;;
    DECISION) color="${_YELLOW}"      ;;
    SUCCESS)  color="${_GREEN}"       ;;
    ERROR)    color="${_RED}"         ;;
    WARN)     color="${_YELLOW}"      ;;
    INFO)     color="${_GRAY}"        ;;
    *)        color="${_RESET}"       ;;
  esac

  echo -e "${color}${message}${_RESET}"
}

# ─── Short wrappers ───────────────────────────────────────────────────────────
log_ok()   { logger SUCCESS "✔  $*"; }
log_err()  { logger ERROR   "✖  $*"; }
log_warn() { logger WARN    "⚠  $*"; }
log_info() { logger INFO    "$*"; }
