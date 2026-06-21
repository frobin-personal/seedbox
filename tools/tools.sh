#!/usr/bin/env bash

set -Eeuo pipefail

##############################################################################
############################### UTIL FUNCTIONS ###############################
##############################################################################

check_utilities () {
  if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
    echo "[$0] Bash 4+ is required. Please run scripts with a modern bash (for example: /usr/bin/env bash)."
    exit 1
  fi

  # Check that docker is installed
  if ! command -v docker >/dev/null 2>&1; then
    echo "[$0] docker does not exist. Install Docker Engine/Desktop first."
    exit 1
  fi

  # Check that jq is installed
  if ! command -v jq >/dev/null 2>&1; then
    echo "[$0] jq does not exist. Install it from here: https://stedolan.github.io/jq/download/"
    echo "[$0] Please install jq version 1.5 or above."
    echo "[$0] Also, please make sure it is in the PATH."
    exit 1
  fi

  # Check that yq is installed
  if ! command -v yq >/dev/null 2>&1; then
    echo "[$0] yq does not exist. Install it from here: https://github.com/mikefarah/yq/releases"
    echo "[$0] Please install yq version 4 or above."
    echo "[$0] Also, please make sure it is in the PATH."
    exit 1
  fi
}

# Set COMPOSE_CMD array to the best available docker compose implementation.
init_compose_command () {
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(docker compose)
    return
  fi

  if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD=(docker-compose)
    return
  fi

  echo "[$0] Docker Compose v2+ is required (docker compose plugin) or legacy docker-compose must be installed."
  exit 1
}

compose () {
  "${COMPOSE_CMD[@]}" "$@"
}

# Portable sed -i helper (GNU/BSD)
sed_inplace_ere () {
  local pattern="$1"
  local file="$2"

  if sed --version >/dev/null 2>&1; then
    sed -i -E "$pattern" "$file"
  else
    sed -E -i '' "$pattern" "$file"
  fi
}