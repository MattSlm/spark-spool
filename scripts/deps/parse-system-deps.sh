#!/usr/bin/env bash
# Updated parse-system-deps.sh (Safe against missing fields)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."

ROOT_DIR="${1:-$REPO_ROOT/deps}"
LOCKFILE="$ROOT_DIR/system-deps.lock"
REPO_SETUP="$ROOT_DIR/deps-setup.sh"

mkdir -p "$ROOT_DIR"
> "$LOCKFILE"
> "$REPO_SETUP"

# --- Install minimal yq manually if needed ---
if ! command -v yq >/dev/null 2>&1; then
  echo "❌ yq not installed. Cannot parse system deps."
  exit 1
fi

declare -A DEPS_REPO

# --- Read all system-deps.yaml files ---
while IFS= read -r -d '' file; do
  echo "🔍 Reading $file"
  count=$(yq '.packages | length' "$file")

  for i in $(seq 0 $((count - 1))); do
    name=$(yq -r ".packages[$i].name" "$file")

    # Safer repo/key detection
    if yq -e ".packages[$i].repo" "$file" >/dev/null 2>&1; then
      repo=$(yq -r ".packages[$i].repo.source // \"\"" "$file")
      key=$(yq -r ".packages[$i].repo.key_url // \"\"" "$file")
    else
      repo=""
      key=""
    fi

    # Detect manual installs
    manual_install=false
    if yq -e ".packages[$i].manual_install" "$file" >/dev/null 2>&1; then
      manual_install=true
    fi

    # --- Handle conflicts ---
    if [[ -n "${DEPS_REPO[$name]:-}" && "$repo" != "${DEPS_REPO[$name]}" ]]; then
      echo "❌ Conflict detected for package '$name':"
      echo "    - Source 1: ${DEPS_REPO[$name]}"
      echo "    - Source 2: $repo"
      exit 1
    fi
    DEPS_REPO["$name"]="$repo"

    # --- Append to lockfile ONLY if not manual install ---
    if [[ "$manual_install" == false ]]; then
      echo "$name" >> "$LOCKFILE"
    fi

    # --- Repo Setup ---
    if [[ -n "$repo" ]]; then
      echo "echo '$repo' > /etc/apt/sources.list.d/$name.list" >> "$REPO_SETUP"
    fi
    if [[ -n "$key" ]]; then
      echo "curl -sL '$key' | apt-key add -" >> "$REPO_SETUP"
    fi

    # --- Manual Install Setup ---
    if [[ "$manual_install" == true ]]; then
      url=$(yq -r ".packages[$i].manual_install.url" "$file")
      target=$(yq -r ".packages[$i].manual_install.target" "$file")
      chmod_val=$(yq -r ".packages[$i].manual_install.chmod" "$file")
      echo "curl -sL '$url' -o '$target'" >> "$REPO_SETUP"
      echo "chmod $chmod_val '$target'" >> "$REPO_SETUP"

      if yq -e ".packages[$i].manual_install.unpack" "$file" >/dev/null 2>&1; then
        unpack_type=$(yq -r ".packages[$i].manual_install.unpack.type" "$file")
        unpack_dest=$(yq -r ".packages[$i].manual_install.unpack.dest" "$file")
        link_to=$(yq -r ".packages[$i].manual_install.unpack.link_to" "$file")
        export_path=$(yq -r ".packages[$i].manual_install.unpack.export_path" "$file")

        if [[ "$unpack_type" == "tar.gz" ]]; then
          echo "tar -xvzf '$target' -C '$unpack_dest'" >> "$REPO_SETUP"
        else
          echo "❌ Unsupported unpack type: $unpack_type"
          exit 1
        fi

        if [[ -n "$link_to" ]]; then
          basename_target=$(basename "$target" .tgz)
          echo "ln -sfn '$unpack_dest/$basename_target' '$link_to'" >> "$REPO_SETUP"
        fi

        if [[ -n "$export_path" ]]; then
          echo "export PATH='$export_path':\$PATH" >> "$REPO_SETUP"
        fi
      fi
    fi

  done

done < <(find "$ROOT_DIR" -name system-deps.yaml -print0)

sort -u "$LOCKFILE" -o "$LOCKFILE"
echo "✅ Dependency lockfile created at $LOCKFILE"
echo "✅ Repo setup script created at $REPO_SETUP"
