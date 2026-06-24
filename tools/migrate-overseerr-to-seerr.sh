#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  source .env
fi

HOST_CONFIG_PATH="${HOST_CONFIG_PATH:-/data/config}"
OVERSEERR_DIR="${HOST_CONFIG_PATH}/overseerr"
SEERR_DIR="${HOST_CONFIG_PATH}/seerr"
BACKUP_DIR="${HOST_CONFIG_PATH}/backups"
STAMP="$(date +%Y%m%d-%H%M%S)"

echo "[migration] Starting Overseerr -> Seerr migration"

mkdir -p "${BACKUP_DIR}"

if [[ -d "${OVERSEERR_DIR}" ]]; then
  backup_file="${BACKUP_DIR}/overseerr-backup-${STAMP}.tar.gz"
  echo "[migration] Creating backup: ${backup_file}"
  tar -czf "${backup_file}" -C "${HOST_CONFIG_PATH}" overseerr

  if [[ -d "${SEERR_DIR}" ]]; then
    echo "[migration] Seerr config folder already exists at ${SEERR_DIR}, skipping data copy"
  else
    echo "[migration] Copying Overseerr data to Seerr folder"
    cp -a "${OVERSEERR_DIR}" "${SEERR_DIR}"
  fi
else
  echo "[migration] WARNING: ${OVERSEERR_DIR} not found, skipping data copy"
fi

if [[ -f config.yaml ]]; then
  if command -v yq >/dev/null 2>&1; then
    echo "[migration] Updating config.yaml service name and host"
    yq -i '(.services[] | select(.name == "overseerr") | .name) = "seerr"' config.yaml
    yq -i '(.services[] | select(.name == "seerr") | .traefik.rules[]? | select(.host == "overseerr.${TRAEFIK_DOMAIN}") | .host) = "seerr.${TRAEFIK_DOMAIN}"' config.yaml
  else
    echo "[migration] WARNING: yq is not installed, config.yaml not updated automatically"
  fi
else
  echo "[migration] No config.yaml found, nothing to patch"
fi

echo "[migration] Migration completed"
echo "[migration] Next steps:"
echo "  1. Run ./run-seedbox.sh"
echo "  2. Open Seerr and complete/verify built-in migration if prompted"
