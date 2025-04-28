#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."

LOCKFILE="$REPO_ROOT/deps/system-deps.lock"
REPO_SETUP="$REPO_ROOT/deps/deps-setup.sh"

echo "🔧 Running repo and manual setup commands..."
if [[ -f "$REPO_SETUP" ]]; then
  bash "$REPO_SETUP"
  apt-get update
else
  echo "⚠️  No repo setup script found at $REPO_SETUP. Continuing without repo additions."
fi

echo "📦 Installing APT packages from lockfile..."
if [[ -f "$LOCKFILE" ]]; then
  xargs -a "$LOCKFILE" apt-get install -y --no-install-recommends
else
  echo "❌ Lockfile not found at $LOCKFILE"
  exit 1
fi

echo "✅ All packages installed."

