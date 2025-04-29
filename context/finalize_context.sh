#!/bin/bash
set -euo pipefail

# Usage: ./finalize_context.sh <ContextID>

CONTEXT_ID="${1:?ContextID not provided}"

# Required variables
SPARK_SPOOL_CONTEXT_MAINDIR="${SPARK_SPOOL_CONTEXT_MAINDIR:?Please export SPARK_SPOOL_CONTEXT_MAINDIR}"
SPARK_HOME="${SPARK_HOME:-}"

# Fallback SPARK_HOME if not set
if [ -z "$SPARK_HOME" ]; then
    if [ -d "/opt/spark" ]; then
        SPARK_HOME="/opt/spark"
        echo "⚡ SPARK_HOME not set, defaulting to /opt/spark"
    else
        echo "❌ SPARK_HOME not set and /opt/spark not found. Exiting."
        exit 1
    fi
fi

# Paths
CONTEXT_DIR="$SPARK_SPOOL_CONTEXT_MAINDIR/$CONTEXT_ID"
CONF_DIR="$SPARK_HOME/conf/$CONTEXT_ID"
LOG_DIR="$SPARK_HOME/logs/$CONTEXT_ID"
TMP_DIR="/scratch/$CONTEXT_ID"
OUTPUT_DATA_DIR="$CONTEXT_DIR/output_data"
SPOOL_CONF="$CONF_DIR/spool-spark-default.conf"

# 1. Create necessary directories
mkdir -p "$CONF_DIR" "$LOG_DIR" "$TMP_DIR" "$OUTPUT_DATA_DIR"

# 2. Load spool config
if [ ! -f "$SPOOL_CONF" ]; then
    echo "❌ spool-spark-default.conf not found for context $CONTEXT_ID!"
    exit 1
fi

# Load config into shell vars safely
while IFS='=' read -r key value; do
    key=$(echo "$key" | tr -d '[:space:]')
    value=$(echo "$value" | tr -d '[:space:]')
    case "$key" in
        spool.*) export "$key"="$value" ;;
        *) ;;  # Ignore unprefixed keys
    esac
done < "$SPOOL_CONF"

# 3. Validate critical fields or fallback to defaults

missing_fields=0

check_or_warn() {
    VAR_NAME="$1"
    DEFAULT_VAL="$2"
    if [ -z "${!VAR_NAME:-}" ]; then
        echo "⚠️ Missing $VAR_NAME. Falling back to default: $DEFAULT_VAL"
        export "$VAR_NAME"="$DEFAULT_VAL"
        missing_fields=1
    fi
}

# Validate all critical fields
check_or_warn spool.spark.executor.memory.gb "6"
check_or_warn spool.spark.executor.memory.overhead.gb "1"
check_or_warn spool.spark.driver.memory.gb "4"
check_or_warn spool.spark.driver.memory.overhead.gb "0"
check_or_warn spool.spark.worker.memory.gb "7"
check_or_warn spool.spark.worker.cores "2"
check_or_warn spool.spark.local.dirs "$TMP_DIR"
check_or_warn spool.spark.log.dir "$LOG_DIR"
check_or_warn spool.spark.gc.opts "-XX:+UseParallelGC -XX:+UseParallelOldGC"
check_or_warn spool.spark.daemon.memory "6g"
check_or_warn spool.spark.daemon.java.opts "-XX:+UseParallelGC -XX:+UseParallelOldGC"
check_or_warn spool.spark.log.maxfiles "10"
check_or_warn spool.spark.log.maxsize "100m"
check_or_warn spool.spark.event_log.enabled "false"
check_or_warn spool.spark.history_log.enabled "false"

if [ $missing_fields -eq 1 ]; then
    echo "⚡ Some fields were missing. Defaults were injected. Updated config printed below:"
fi

# 4. Print effective config for debug
echo "==== Final Effective Spool Config ===="
env | grep "^spool\."
echo "======================================="

# 5. Assemble spark-env.sh
cat > "$CONF_DIR/spark-env.sh" <<EOF
#!/usr/bin/env bash
# Auto-generated spark-env.sh for context $CONTEXT_ID

export SPARK_EXECUTOR_MEMORY="${spool.spark.executor.memory.gb}g"
export SPARK_EXECUTOR_MEMORY_OVERHEAD="${spool.spark.executor.memory.overhead.gb}g"
export SPARK_DRIVER_MEMORY="${spool.spark.driver.memory.gb}g"
export SPARK_DRIVER_MEMORY_OVERHEAD="${spool.spark.driver.memory.overhead.gb}g"
export SPARK_WORKER_MEMORY="${spool.spark.worker.memory.gb}g"
export SPARK_WORKER_CORES="${spool.spark.worker.cores}"
export SPARK_LOCAL_DIRS="$spool.spark.local.dirs"
export SPARK_LOG_DIR="$spool.spark.log.dir"
export SPARK_LOG_MAXFILES="$spool.spark.log.maxfiles"
export SPARK_LOG_MAXSIZE="$spool.spark.log.maxsize"
export SPARK_GC_OPTS="$spool.spark.gc.opts"
export SPARK_DAEMON_MEMORY="$spool.spark.daemon.memory"
export SPARK_DAEMON_JAVA_OPTS="$spool.spark.daemon.java.opts"
EOF

chmod +x "$CONF_DIR/spark-env.sh"

# 6. Assemble spark-defaults.conf
cat > "$CONF_DIR/spark-defaults.conf" <<EOF
# Auto-generated spark-defaults.conf for context $CONTEXT_ID

spark.executor.memory ${spool.spark.executor.memory.gb}g
spark.driver.memory ${spool.spark.driver.memory.gb}g
spark.eventLog.enabled ${spool.spark.event_log.enabled}
spark.history.fs.logDirectory file:///dev/null
spark.eventLog.dir file:///dev/null
spark.local.dir $spool.spark.local.dirs
EOF

# 7. Assemble log4j.properties
cat > "$CONF_DIR/log4j.properties" <<EOF
# Auto-generated log4j.properties for context $CONTEXT_ID

log4j.rootCategory=INFO, file
log4j.appender.file=org.apache.log4j.RollingFileAppender
log4j.appender.file.File=$LOG_DIR/class.log
log4j.appender.file.MaxFileSize=${spool.spark.log.maxsize}
log4j.appender.file.MaxBackupIndex=${spool.spark.log.maxfiles}
log4j.appender.file.layout=org.apache.log4j.PatternLayout
log4j.appender.file.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n
EOF

# 8. Create empty log files
touch "$LOG_DIR/loader.log" "$LOG_DIR/class.log" "$LOG_DIR/stdout.log" "$LOG_DIR/stderr.log"

# 9. Copy spool config into logs (optional inside JVM)
cp "$SPOOL_CONF" "$LOG_DIR/spool-spark-default.conf"

# 10. Save context env metadata
cat >> "$CONTEXT_DIR/.spool-env.sh" <<EOF

# Finalizer injected
export SPARK_SPOOL_CONTEXT_LOG_FILE="logs/loader.log"
export SPARK_SPOOL_CONTEXT_SPARK_LOCAL_DIR="$TMP_DIR"
EOF

# 11. Done
echo "✅ Finalized context $CONTEXT_ID:"
echo "   • Conf dir: $CONF_DIR"
echo "   • Logs dir: $LOG_DIR"
echo "   • Scratch dir: $TMP_DIR"
