#!/usr/bin/env bash
set -euo pipefail

mkdir -p /workspace /samples /config /data/specimens /run/sshd
chown -R examiner:examiner /workspace /config /data/specimens

if [ ! -f /config/rea-env.sh ]; then
  cat >/config/rea-env.sh <<'EOF'
export OPENAI_BASE_URL="${OPENAI_BASE_URL:-http://rea-llm:8080/v1}"
export OPENAI_API_KEY="${OPENAI_API_KEY:-none}"
export OPENAI_MODEL="${OPENAI_MODEL:-qwen3.8-27b-uncensored}"
export GHIDRA_INSTALL_DIR="${GHIDRA_INSTALL_DIR:-/opt/ghidra}"
export GHIDRA_HEADLESS="${GHIDRA_HEADLESS:-/opt/ghidra/support/analyzeHeadless}"
export REA_SPECIMENS="${REA_SPECIMENS:-/data/specimens}"
export HOPPER_PATH="${HOPPER_PATH:-/opt/hopper}"
EOF
fi

exec "$@"
