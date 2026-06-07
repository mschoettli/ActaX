#!/usr/bin/env bash
#
# Nexus installer bootstrap.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/mschoettli/Nexus/main/install.sh | sudo bash
#
set -euo pipefail

ARCHIVE_URL="${NEXUS_ARCHIVE_URL:-https://github.com/mschoettli/Nexus/archive/refs/heads/main.tar.gz}"
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
LOCAL_INSTALLER="${SCRIPT_DIR}/scripts/install-full.sh"

if [ "$(id -u)" -ne 0 ]; then
  echo "Nexus must be installed with root privileges." >&2
  echo "Run: curl -fsSL https://raw.githubusercontent.com/mschoettli/Nexus/main/install.sh | sudo bash" >&2
  exit 1
fi

if [ -f "$LOCAL_INSTALLER" ] && [ -f "${SCRIPT_DIR}/server.py" ]; then
  exec bash "$LOCAL_INSTALLER" "$@"
fi

command -v curl >/dev/null 2>&1 || {
  echo "curl is required for the one-command installer." >&2
  exit 1
}

command -v tar >/dev/null 2>&1 || {
  echo "tar is required for the one-command installer." >&2
  exit 1
}

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

echo "Downloading Nexus..."
curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$WORK_DIR"

NEXUS_DIR="$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
REMOTE_INSTALLER="${NEXUS_DIR}/scripts/install-full.sh"

if [ -z "$NEXUS_DIR" ] || [ ! -f "$REMOTE_INSTALLER" ] || [ ! -f "${NEXUS_DIR}/server.py" ]; then
  echo "Downloaded archive is not a valid Nexus release." >&2
  exit 1
fi

NEXUS_SOURCE_DIR="$NEXUS_DIR" bash "$REMOTE_INSTALLER" "$@"
