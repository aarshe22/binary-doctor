#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

docker compose ps
curl -fsS "http://127.0.0.1:${LLM_PORT:-12435}/v1/models" | jq .
docker exec REA rea-doctor
docker exec REA command -v triage-specimen
docker exec REA command -v qemu-aarch64-static
docker exec REA command -v gdb-multiarch
docker exec REA command -v unblob
docker exec REA-opencode opencode --version
