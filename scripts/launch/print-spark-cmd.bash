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

# patch spark-class dynamically
(
  set +e
  # Export fake exec function if magic var is set
  function exec() {
    if [[ "$SPARK_SPOOL_PRINT_CMD_ONLY" == "1" ]]; then
      printf "%s\n" "${CMD[@]}"
      exit 0
    else
      command exec "$@"
    fi
  }
  . "$SPARK_HOME/bin/spark-class"
)

export SPARK_HOME="$REAL_SPARK_HOME"

