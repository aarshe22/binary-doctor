#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

./scripts/update-git-deps.sh

cat <<'EOF'

Dependency checkouts are current.

Next steps:
  docker compose build --pull rea-llm
  docker compose up -d --force-recreate rea-llm

For repeatable builds, pin refs in .env, for example:
  LLAMA_CPP_REF=<commit-sha>
EOF
