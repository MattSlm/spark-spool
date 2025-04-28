#!/usr/bin/env bash
# source-env.sh
# 🚀 Prepare local environment for Spark-Spool builds

# Fail fast
set -euo pipefail

# Resolve the repo root dynamically (no matter where user calls from)
export SPARK_SPOOL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Export paths for our scripts and Makefiles
export PATH="$SPARK_SPOOL_ROOT/scripts:$PATH"

# Tell the Makefile where the deps live
export SPARK_SPOOL_DEPS="$SPARK_SPOOL_ROOT/deps"

# Optionally: Warn if user forgot to install deps
if ! command -v yq >/dev/null 2>&1; then
    echo "⚠️  Warning: 'yq' not found. You probably need to run: make deps"
fi

# Optionally: Export Gramine-specific variables
export GRAMINE_LOG_LEVEL=error

echo "✅ Environment prepared. You can now run 'make' commands."

