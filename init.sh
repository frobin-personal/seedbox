#!/usr/bin/env bash

set -Eeuo pipefail

INSTALL_LOCAL_PERSIST=0

for i in "$@"; do
  case $i in
    --with-local-persist)
      INSTALL_LOCAL_PERSIST=1
      ;;
    *)
      echo "[$0] ERROR: unknown parameter \"$i\""
      exit 1
      ;;
  esac
done

echo "[$0] Initializing..."

# Create docker network
docker network create traefik-network 2>&1 || true

if [[ ${INSTALL_LOCAL_PERSIST} == "1" ]]; then
  echo "Installing local-persist docker driver... (will prompt for password for sudo access)"
  sudo tools/local-persist.sh
else
  echo "Skipping local-persist install (default 2026 mode uses native local bind volumes)."
  echo "Use --with-local-persist if you need legacy compatibility."
fi

# Copy env file
if [[ ! -f .env ]]; then
  cp .env.sample .env
  echo "[$0] Please edit .env file"
fi

# Copy custom env file
if [[ ! -f .env.custom ]]; then
  cp .env.custom.sample .env.custom
  echo "[$0] Please edit .env.custom file if you want more customization (see documentation)."
fi

# Copy sample docker compose file
if [[ ! -f docker-compose.yaml ]]; then
  cp docker-compose.sample.yaml docker-compose.yaml
fi

echo "[$0] Done."
exit 0