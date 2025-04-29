#!/bin/bash
set -euo pipefail

# Usage: ./finalize_context.sh <ContextID> [LogLevel]

CONTEXT_ID="${1:?ContextID not provided}"
LOG_LEVEL="${2:-error}"  # Default log level is 'error' if not provided

# Required variables
if [ -z "${SPARK_SPOOL_CONTEXT_MAINDIR:-}" ]; then
    echo "❌ SPARK_SPOOL_CONTEXT_MAINDIR is not set. Please export it."
    exit 1
fi
if [ -z "${SPARK_HOME:-}" ]; then
    echo "❌ SPARK_HOME is not set. Please export it."
    exit 1
fi

# Paths
CONTEXT_DIR="$SPARK_SPOOL_CONTEXT_MAINDIR/$CONTEXT_ID"
CONF_DIR="$SPARK_HOME/conf/$CONTEXT_ID"
LOG_DIR="$SPARK_HOME/logs/$CONTEXT_ID"
TMP_DIR="/scratch/$CONTEXT_ID"
OUTPUT_DATA_DIR="$CONTEXT_DIR/output_data"

# 1. Create necessary directories
mkdir -p "$CONF_DIR" "$LOG_DIR" "$TMP_DIR" "$OUTPUT_DATA_DIR"

# 2. Reserve a WebUI port safely
WEBUI_PORT=$(python3 -c '
import socket
s = socket.socket()
s.bind(("", 0))
port = s.getsockname()[1]
s.close()
print(port)
')

# 3. Copy and patch spark-defaults.conf
if [ ! -f "$SPARK_HOME/conf/spark-defaults.conf" ]; then
    echo "❌ spark-defaults.conf missing! Please copy the .template first."
    exit 1
fi

cp "$SPARK_HOME/conf/spark-defaults.conf" "$CONF_DIR/spark-defaults.conf"

{
  echo ""
  echo "# Auto-injected by finalize_context.sh"
  echo "spark.eventLog.enabled false"
  echo "spark.eventLog.dir file:///dev/null"
  echo "spark.history.fs.logDirectory file:///dev/null"
  echo "spark.ui.port $WEBUI_PORT"
} >> "$CONF_DIR/spark-defaults.conf"

# 4. Copy and patch log4j.properties
cp "$SPARK_HOME/conf/log4j.properties" "$CONF_DIR/log4j.properties"
sed -i "s|^log4j.appender.file.File=.*|log4j.appender.file.File=$LOG_DIR/class.log|" "$CONF_DIR/log4j.properties"

# 5. Create safe default spark-env.sh
cat > "$CONF_DIR/spark-env.sh" <<EOF
#!/usr/bin/env bash
# Auto-generated spark-env.sh for context $CONTEXT_ID

export SPARK_MASTER_HOST="\${SPARK_MASTER_HOST:-127.0.0.1}"
export SPARK_MASTER_PORT="\${SPARK_MASTER_PORT:-7077}"
export SPARK_MASTER_WEBUI_PORT="$WEBUI_PORT"
export SPARK_LOG_DIR="$LOG_DIR"
export SPARK_LOCAL_DIRS="$TMP_DIR"

export SPARK_EXECUTOR_MEMORY_GB="\${SPARK_EXECUTOR_MEMORY_GB:-6}"
export SPARK_EXECUTOR_MEMORY_OVERHEAD_GB="\${SPARK_EXECUTOR_MEMORY_OVERHEAD_GB:-1}"
export SPARK_WORKER_MEMORY_GB="\${SPARK_WORKER_MEMORY_GB:-7}"
export SPARK_WORKER_CORES="\${SPARK_WORKER_CORES:-2}"
export SPARK_DRIVER_MEMORY_GB="\${SPARK_DRIVER_MEMORY_GB:-4}"
export SPARK_DRIVER_MEMORY_OVERHEAD_GB="\${SPARK_DRIVER_MEMORY_OVERHEAD_GB:-0}"

export SPARK_DAEMON_MEMORY="\${SPARK_DAEMON_MEMORY:-6g}"
export SPARK_GC_OPTS="\${SPARK_GC_OPTS:--XX:+UseParallelGC -XX:+UseParallelOldGC}"
export SPARK_DAEMON_JAVA_OPTS="\${SPARK_DAEMON_JAVA_OPTS:--XX:+UseParallelGC -XX:+UseParallelOldGC}"

export SPARK_LOG_LEVEL="\${SPARK_LOG_LEVEL:-$LOG_LEVEL}"
export SPARK_LOG_MAXFILES="\${SPARK_LOG_MAXFILES:-10}"
export SPARK_LOG_MAXSIZE="\${SPARK_LOG_MAXSIZE:-100m}"
EOF

chmod +x "$CONF_DIR/spark-env.sh"

# 6. Create empty log files
touch "$LOG_DIR/loader.log" "$LOG_DIR/class.log" "$LOG_DIR/stdout.log" "$LOG_DIR/stderr.log"

# 7. Copy spool-spark-default.conf into LOG_DIR (JVMs may want it inside enclave)
cp "$SPARK_HOME/conf/spool-spark-default.conf" "$LOG_DIR/spool-spark-default.conf"

# 8. Save metadata into .spool-env.sh
cat >> "$CONTEXT_DIR/.spool-env.sh" <<EOF

# Finalizer injected
export SPARK_SPOOL_CONTEXT_WEBUI_PORT="$WEBUI_PORT"
export SPARK_SPOOL_CONTEXT_LOG_LEVEL="$LOG_LEVEL"
export SPARK_SPOOL_CONTEXT_LOG_FILE="logs/loader.log"
export SPARK_SPOOL_CONTEXT_SPARK_LOCAL_DIR="$TMP_DIR"
EOF

echo "✅ Finalized context $CONTEXT_ID:"
echo "   • WebUI port: $WEBUI_PORT"
echo "   • Log level: $LOG_LEVEL"
echo "   • SPARK_LOCAL_DIRS: $TMP_DIR"
echo "   • Conf dir: $CONF_DIR"
echo "   • Logs dir: $LOG_DIR"
