#!/usr/bin/env bash
set -eo pipefail  # <=== Drop the -u flag!

# === Wrapper to extract Spark launch command ===

SPARK_HOME_IN_ENCLAVE="/opt/spark"
CONTEXT_DIR="${CONTEXT_DIR:-}"

if [[ -z "$CONTEXT_DIR" ]]; then
    echo "❌ CONTEXT_DIR must be set!"
    exit 1
fi

: "${SPARK_ENV_LOADED:=}"

REAL_SPARK_HOME="${SPARK_HOME:-}"
export SPARK_HOME="$CONTEXT_DIR/opt/spark"

(
    set +e
    . "$SPARK_HOME/bin/spark-class"
    printf "%s\n" "${CMD[@]}"
)

export SPARK_HOME="$REAL_SPARK_HOME"

