#!/bin/bash
set -euo pipefail

CONTEXT_ID="${1:?ContextID not provided}"

SPARK_HOME="${SPARK_HOME:-/opt/spark}"
SPARK_SPOOL_CONTEXT_MAINDIR="${SPARK_SPOOL_CONTEXT_MAINDIR:-/tmp/spool-contexts}"
SCRATCH_DIR="/scratch"

CONTEXT_DIR="$SPARK_SPOOL_CONTEXT_MAINDIR/$CONTEXT_ID"
CONF_DIR="$SPARK_HOME/conf/$CONTEXT_ID"
LOGS_DIR="$SPARK_HOME/logs/$CONTEXT_ID"
SCRATCH_CONTEXT_DIR="$SCRATCH_DIR/$CONTEXT_ID"

echo "🧹 Purging context: $CONTEXT_ID"

# Remove context main dir
if [ -d "$CONTEXT_DIR" ]; then
    echo "  • Removing context dir: $CONTEXT_DIR"
    rm -rf "$CONTEXT_DIR"
fi

# Remove conf dir
if [ -d "$CONF_DIR" ]; then
    echo "  • Removing conf dir: $CONF_DIR"
    rm -rf "$CONF_DIR"
fi

# Remove logs dir
if [ -d "$LOGS_DIR" ]; then
    echo "  • Removing logs dir: $LOGS_DIR"
    rm -rf "$LOGS_DIR"
fi

# Remove scratch dir
if [ -d "$SCRATCH_CONTEXT_DIR" ]; then
    echo "  • Removing scratch dir: $SCRATCH_CONTEXT_DIR"
    rm -rf "$SCRATCH_CONTEXT_DIR"
fi

echo "✅ Context $CONTEXT_ID purged."

