#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

mode="${1:-live}"

case "$mode" in
  live)
    docker compose up -d rea-llm rea
    docker compose up -d opencode
    docker exec REA-opencode update-opencode
    docker exec REA-opencode opencode --version
    ;;
  rebuild)
    docker compose build --pull --no-cache rea
    docker compose up -d --force-recreate rea opencode
    docker exec REA-opencode opencode --version
    ;;
  *)
    cat >&2 <<'EOF'
usage: ./update-opencode.sh [live|rebuild]

live    Update OpenCode and REA packages inside the running REA-opencode container.
rebuild Rebuild the REA image with the latest configured OpenCode/REA package versions.
EOF
    exit 2
    ;;
esac
