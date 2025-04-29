#!/bin/bash
set -euo pipefail

CONTEXT_ID="${1:?ContextID not provided}"
CLASS="${2:?Class not provided}"
CLASS_ARGS="${3:-}"

SPARK_SPOOL_CONTEXT_MAINDIR="${SPARK_SPOOL_CONTEXT_MAINDIR:-/tmp/spool-contexts}"
CONTEXT_DIR="$SPARK_SPOOL_CONTEXT_MAINDIR/$CONTEXT_ID"

echo "🔨 Creating Gramine Spark Context..."

mkdir -p "$CONTEXT_DIR/output_data"

# Write minimal .spool-env.sh
cat > "$CONTEXT_DIR/.spool-env.sh" <<EOF
export SPARK_SPOOL_CONTEXT_ID="$CONTEXT_ID"
export SPARK_SPOOL_CONTEXT_CLASS="$CLASS"
export SPARK_SPOOL_CONTEXT_CLASS_ARGS="$CLASS_ARGS"
EOF

echo "✅ Created context structure at $CONTEXT_DIR"
