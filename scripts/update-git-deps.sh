#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

manifest="${DEPS_MANIFEST:-deps/repos.tsv}"
lock_file="${DEPS_LOCK_FILE:-deps/LOCK.md}"

if [ ! -f "$manifest" ]; then
  echo "Dependency manifest not found: $manifest" >&2
  exit 1
fi

mkdir -p deps

tmp_lock="$(mktemp)"
{
  echo "# Dependency Lock"
  echo
  echo "Updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo "| Name | Ref | Commit | Path | URL |"
  echo "| --- | --- | --- | --- | --- |"
} > "$tmp_lock"

if [ -f .gitmodules ]; then
  git submodule sync --recursive
  git submodule update --init --recursive
  git submodule foreach --recursive 'git fetch --all --tags --prune && git pull --ff-only || true'
fi

while IFS=$'\t' read -r name url ref path extra; do
  case "${name:-}" in
    ""|\#*) continue ;;
  esac

  if [ -n "${extra:-}" ]; then
    echo "Invalid dependency row for $name: expected 4 tab-separated fields" >&2
    exit 1
  fi

  ref="$(eval "printf '%s' \"$ref\"")"
  path="$(eval "printf '%s' \"$path\"")"

  if [ -z "$name" ] || [ -z "$url" ] || [ -z "$ref" ] || [ -z "$path" ]; then
    echo "Invalid dependency row: name, url, ref, and path are required" >&2
    exit 1
  fi

  echo "==> $name"
  if [ ! -d "$path/.git" ]; then
    mkdir -p "$(dirname "$path")"
    git clone "$url" "$path"
  fi

  git -C "$path" remote set-url origin "$url"
  git -C "$path" fetch --all --tags --prune

  if git -C "$path" show-ref --verify --quiet "refs/remotes/origin/$ref"; then
    git -C "$path" checkout "$ref"
    git -C "$path" pull --ff-only origin "$ref"
  else
    git -C "$path" checkout --detach "$ref"
  fi

  git -C "$path" submodule update --init --recursive
  commit="$(git -C "$path" rev-parse HEAD)"
  printf '| `%s` | `%s` | `%s` | `%s` | %s |\n' "$name" "$ref" "$commit" "$path" "$url" >> "$tmp_lock"
done < "$manifest"

mv "$tmp_lock" "$lock_file"
echo "Dependency lock updated: $lock_file"
