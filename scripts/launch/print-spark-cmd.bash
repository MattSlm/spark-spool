#!/usr/bin/env bash
set -euo pipefail

# === Wrapper to extract Spark launch command ===

SPARK_HOME_IN_ENCLAVE="/opt/spark"
CONTEXT_DIR="${CONTEXT_DIR:-}"

if [[ -z "$CONTEXT_DIR" ]]; then
    echo "❌ CONTEXT_DIR must be set!"
    exit 1
fi

# Avoid unbound variable error for SPARK_ENV_LOADED
: "${SPARK_ENV_LOADED:=}"

# Save real SPARK_HOME
REAL_SPARK_HOME="${SPARK_HOME:-}"

# Override SPARK_HOME ONLY inside the wrapper
export SPARK_HOME="$CONTEXT_DIR/opt/spark"

# Now load spark-class normally
(
    set +e
    . "$SPARK_HOME/bin/spark-class"
    printf "%s\n" "${CMD[@]}"
)

# Restore real SPARK_HOME afterwards
export SPARK_HOME="$REAL_SPARK_HOME"
