#!/bin/bash
set -euo pipefail

# Usage: ./create_context.sh <ContextID> <Class> [ClassArgs...]

CONTEXT_ID="${1:?ContextID not provided}"
CLASS="${2:?Class (e.g., master, worker) not provided}"
shift 2
CLASS_ARGS="$*"

TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"

# Load global spool config
if [ -z "${SPARK_SPOOL_CONTEXT_MAINDIR:-}" ]; then
  echo "❌ SPARK_SPOOL_CONTEXT_MAINDIR is not set. Please export it or define it in .spool-env.sh"
  exit 1
fi

CONTEXT_DIR="$SPARK_SPOOL_CONTEXT_MAINDIR/$CONTEXT_ID"

mkdir -p "$CONTEXT_DIR"
mkdir -p "$CONTEXT_DIR/output_data"

# Save context metadata
cat > "$CONTEXT_DIR/.spool-env.sh" <<EOF
# Spool Context Metadata
export SPARK_SPOOL_CONTEXT_ID="$CONTEXT_ID"
export SPARK_SPOOL_CONTEXT_CLASS="$CLASS"
export SPARK_SPOOL_CONTEXT_CLASS_ARGS="$CLASS_ARGS"
export SPARK_SPOOL_CONTEXT_DIR="$CONTEXT_DIR"
EOF

echo "✅ Context $CONTEXT_ID created at $CONTEXT_DIR"
echo "ℹ️ Class: $CLASS"
echo "ℹ️ Args: $CLASS_ARGS"

