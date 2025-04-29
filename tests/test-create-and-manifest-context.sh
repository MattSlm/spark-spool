#!/bin/bash

set -euo pipefail

# === Test: Create, finalize, and build manifest for a sample context ===

# Config
CONTEXT_ID="test_sanity"
CLASS="worker"
CLASS_ARGS=""
LOG_LEVEL="info"
MODE="direct"  # direct = gramine-direct, fast for test

SPARK_SPOOL_CONTEXT_MAINDIR=${SPARK_SPOOL_CONTEXT_MAINDIR:-/tmp/spool-contexts}
SPARK_HOME=${SPARK_HOME:-/opt/spark}

CONTEXT_DIR="$SPARK_SPOOL_CONTEXT_MAINDIR/$CONTEXT_ID"

echo "🛠️  [1/5] Creating context: $CONTEXT_ID"
make create_context CONTEXT_ID="$CONTEXT_ID" CLASS="$CLASS" CLASS_ARGS="$CLASS_ARGS"

echo "🛠️  [2/5] Finalizing context: $CONTEXT_ID"
make finalize_context CONTEXT_ID="$CONTEXT_ID" LOG_LEVEL="$LOG_LEVEL"

echo "🛠️  [3/5] Building manifest for context: $CONTEXT_ID (mode=$MODE)"
make build_manifest CONTEXT_ID="$CONTEXT_ID" MODE="$MODE"

echo "🔍 [4/5] Checking expected critical files..."
critical_files=(
    "$SPARK_HOME/conf/$CONTEXT_ID/spark-env.sh"
    "$SPARK_HOME/conf/$CONTEXT_ID/spark-defaults.conf"
    "$SPARK_HOME/conf/$CONTEXT_ID/log4j.properties"
    "$SPARK_HOME/logs/$CONTEXT_ID/loader.log"
    "$SPARK_HOME/logs/$CONTEXT_ID/class.log"
    "$CONTEXT_DIR/.spool-env.sh"
    "$CONTEXT_DIR/manifest"
)

for f in "${critical_files[@]}"; do
    if [ ! -f "$f" ]; then
        echo "❌ Missing critical file: $f"
        exit 1
    fi
done

echo "✅ All critical files exist."

echo "🔍 [5/5] Checking manifest correctness..."

required_mounts=(
    "/scratch/$CONTEXT_ID"
    "$SPARK_HOME/logs/$CONTEXT_ID/loader.log"
    "$SPARK_HOME/logs/$CONTEXT_ID/class.log"
)

for m in "${required_mounts[@]}"; do
    if ! grep -q "$m" "$CONTEXT_DIR/manifest"; then
        echo "❌ Missing mount or allowed file reference in manifest: $m"
        exit 1
    fi
done

echo "✅ Manifest correctly includes scratch, loader.log, and class.log."

echo "🎉 Test PASSED for context: $CONTEXT_ID"

