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
for tool in triage-specimen analyze-raw-ghidra qemu-aarch64-static gdb-multiarch unblob llvm-objdump z80dasm ca65 ld65 vol; do
  docker exec REA sh -lc "command -v $tool"
done
test -x ./shell.sh
docker exec REA-opencode opencode --version
