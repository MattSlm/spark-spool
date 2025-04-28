#!/usr/bin/env bash
# check-deps.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."

LOCKFILE="$REPO_ROOT/deps/system-deps.lock"
SYSTEM_DEPS_FILE="$REPO_ROOT/deps/system-deps.yaml"

echo "🔍 Checking if all system dependencies are installed..."

missing=()

# --- Step 1. Check APT-installed packages ---
if [[ -f "$LOCKFILE" ]]; then
  while read -r package; do
    # Check if this package is manually installed (defined in system-deps.yaml)
    if grep -q "name: $package" "$SYSTEM_DEPS_FILE"; then
      if yq '.packages[] | select(.name == "'"$package"'") | has("manual_install")' "$SYSTEM_DEPS_FILE" | grep -q true; then
        # It's manual, skip dpkg check
        continue
      fi
    fi

    # Regular APT package
    if ! dpkg -s "$package" >/dev/null 2>&1; then
      echo "❌ Missing APT package: $package"
      missing+=("$package")
    fi
  done < "$LOCKFILE"
else
  echo "⚠️ No lockfile found at $LOCKFILE. Skipping APT check."
fi

# --- Step 2. Check MANUAL-installed binaries ---
if [[ -f "$SYSTEM_DEPS_FILE" ]]; then
  manual_bins=($(yq -r '.packages[] | select(has("manual_install")) | .name' "$SYSTEM_DEPS_FILE"))
  
  for bin in "${manual_bins[@]}"; do
    if ! command -v "$bin" >/dev/null 2>&1; then
      echo "❌ Missing manually installed binary: $bin"
      missing+=("$bin")
    fi
  done
fi

# --- Step 3. Result ---
if (( ${#missing[@]} > 0 )); then
  echo "⚠️ Some dependencies are missing: ${missing[*]}"
  exit 1
fi

echo "✅ All dependencies installed and available!"

