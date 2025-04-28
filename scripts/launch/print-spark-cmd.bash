#!/usr/bin/env bash
set -euo pipefail

SPARK_HOME="${SPARK_HOME:-/opt/spark}"

# Find JAVA binary
if [[ -n "${JAVA_HOME:-}" ]]; then
  RUNNER="$JAVA_HOME/bin/java"
else
  RUNNER="java"
fi

# Setup classpath
if [[ -d "${SPARK_HOME}/jars" ]]; then
  SPARK_JARS_DIR="${SPARK_HOME}/jars"
else
  SPARK_JARS_DIR="${SPARK_HOME}/assembly/target/scala-2.12/jars"
fi
LAUNCH_CLASSPATH="$SPARK_JARS_DIR/*"

# Build launcher command
launcher_cmd=(
  "$RUNNER"
  -Xmx128m
  -cp "$LAUNCH_CLASSPATH"
  org.apache.spark.launcher.Main
  "$@"
)

# Run launcher but only capture CMD output
DELIM=$'\n'
CMD_START_FLAG="false"
CMD=()

while IFS= read -d "$DELIM" -r ARG; do
  if [[ "$CMD_START_FLAG" == "true" ]]; then
    CMD+=("$ARG")
  else
    if [[ "$ARG" == $'\0' ]]; then
      DELIM=''
      CMD_START_FLAG="true"
    elif [[ "$ARG" != "" ]]; then
      echo "$ARG"
    fi
  fi
done < <("${launcher_cmd[@]}")

# Print command that would be executed
printf "%s\n" "${CMD[@]}"

