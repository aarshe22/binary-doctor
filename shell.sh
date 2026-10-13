#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

service="${EXAMINER_SHELL_SERVICE:-opencode}"
container="${EXAMINER_SHELL_CONTAINER:-REA-opencode}"
workdir="${EXAMINER_SHELL_WORKDIR:-/data/specimens}"

if ! docker compose ps --status running --services | grep -qx "$service"; then
  echo "Starting Binary Doctor services..."
  docker compose up -d "$service"
fi

exec docker exec -it \
  -w "$workdir" \
  "$container" \
  bash -lc '
    set -euo pipefail
    if [ -f /config/rea-env.sh ]; then
      # shellcheck disable=SC1091
      . /config/rea-env.sh
    fi
    mkdir -p /data/specimens
    cd /data/specimens
    cat <<EOF
Binary Doctor shell

Working directory: /data/specimens

Recommended layout:
  <case>/originals  - untouched source files
  <case>/extracted  - unpacked or converted outputs
  <case>/ghidra     - Ghidra projects and exports
  <case>/notes      - hashes, commands, observations
  <case>/reports    - final writeups

Useful first commands:
  mkdir -p my-case/{originals,extracted,ghidra,notes,reports}
  triage-specimen my-case/originals/target.bin my-case
  opencode
EOF
    exec bash
  '
