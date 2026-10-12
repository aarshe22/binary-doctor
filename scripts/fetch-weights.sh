#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

mkdir -p models

repo_id="${QWEN_REPO_ID:-JonathanColetti/Qwen3.8-27B-Uncensored-GGUF}"
model_file="${QWEN_MODEL_FILE:-Qwen3.8-27B-Uncensored-Q4_K_M.gguf}"
output="${QWEN_MODEL_PATH:-./models/${model_file}}"

if [ "${output#/}" = "$output" ]; then
  output="$(pwd)/${output#./}"
fi

mkdir -p "$(dirname "$output")"

if [ -s "$output" ]; then
  echo "Model already present: $output"
  exit 0
fi

url="https://huggingface.co/${repo_id}/resolve/main/${model_file}"
tmp="${output}.tmp"
headers=()
if [ -n "${HF_TOKEN:-}" ]; then
  headers=(-H "Authorization: Bearer ${HF_TOKEN}")
fi

echo "Downloading ${repo_id}/${model_file}"
rm -f "$tmp"
curl --fail --location --continue-at - --retry 8 --retry-delay 5 \
  "${headers[@]}" \
  --output "$tmp" \
  "$url"
mv "$tmp" "$output"
echo "Model ready: $output"
