#!/usr/bin/env bash
set -euo pipefail

mkdir -p /root/.config/opencode /root/.local/share/opencode

if [ ! -f /root/.local/share/opencode/auth.json ]; then
  cat >/root/.local/share/opencode/auth.json <<'JSON'
{
  "examiner-qwen": {
    "type": "api",
    "key": "none"
  }
}
JSON
fi

exec "$@"
