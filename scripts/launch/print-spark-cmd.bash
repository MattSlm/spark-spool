#!/usr/bin/env bash
set -euo pipefail

echo "🔵 [Wrapper] Starting spark-class wrapper..."

# === Detect Spark Home ===
if [[ -z "${SPARK_HOME:-}" ]]; then
  echo "❌ SPARK_HOME not set in environment."
  exit 1
fi
echo "✅ [Wrapper] SPARK_HOME = $SPARK_HOME"

# === Find spark-class ===
SPARK_CLASS_SCRIPT="$SPARK_HOME/bin/spark-class"

if [[ ! -f "$SPARK_CLASS_SCRIPT" ]]; then
  echo "❌ [Wrapper] spark-class not found at $SPARK_CLASS_SCRIPT"
  exit 1
fi
echo "✅ [Wrapper] Found spark-class script."

# === Source spark-class to build CMD ===
echo "🔵 [Wrapper] Sourcing spark-class to capture CMD array..."
(
  set +e
  # ⚡ Inside subshell
  source "$SPARK_CLASS_SCRIPT" "$@" || {
    echo "❌ [Wrapper] Failed inside sourced spark-class."
    exit 1
  }

  # === After sourcing ===
  if [[ ${#CMD[@]:-0} -eq 0 ]]; then
    echo "❌ [Wrapper] CMD array is empty after sourcing."
    exit 1
  fi

  echo "✅ [Wrapper] CMD array captured successfully:"
  for arg in "${CMD[@]}"; do
    echo "   - $arg"
  done
)
echo "✅ [Wrapper] Completed spark-class wrapper."
