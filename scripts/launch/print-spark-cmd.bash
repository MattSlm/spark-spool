#!/usr/bin/env bash
set -euo pipefail

# 💡 Spark expects this variable, or else load-spark-env.sh crashes
export SPARK_ENV_LOADED=1

# Wrapper around spark-class to extract the launch command
SPARK_HOME="${SPARK_HOME:-/opt/spark}"

if [ -z "${SPARK_HOME}" ]; then
  echo "❌ SPARK_HOME is not set."
  exit 1
fi

# Accepts args: spark main class + spark args
(
  set +e
  . "$SPARK_HOME/bin/spark-class" "$@"   # <-- Correctly passes positional args
  printf "%s\n" "${CMD[@]}"
)

