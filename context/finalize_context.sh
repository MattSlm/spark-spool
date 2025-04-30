#!/bin/bash
set -euo pipefail

# Usage: ./finalize_context.sh <ContextID>

CONTEXT_ID="${1:?ContextID not provided}"

# Load required global vars
SPARK_SPOOL_CONTEXT_MAINDIR="${SPARK_SPOOL_CONTEXT_MAINDIR:?Please export SPARK_SPOOL_CONTEXT_MAINDIR}"
SPARK_HOME="${SPARK_HOME:-}"

# Fallback SPARK_HOME
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

# 2. Load spool config into an associative array
declare -A conf_map

if [ ! -f "$SPOOL_CONF" ]; then
    echo "❌ spool-spark-default.conf not found for context $CONTEXT_ID!"
    exit 1
fi

while IFS='=' read -r key val; do
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
    key="$(echo "$key" | tr -d '[:space:]')"
    val="$(echo "$val" | tr -d '[:space:]')"
    conf_map["$key"]="$val"
done < "$SPOOL_CONF"

# 3. Validate critical fields, inject missing if necessary
missing_fields=0

check_or_warn() {
    local key="$1"
    local default="$2"
    if [ -z "${conf_map[$key]:-}" ]; then
        echo "⚠️ Missing $key. Injecting default: $default"
        conf_map["$key"]="$default"
        missing_fields=1
    fi
}

# Spark tuning fields
check_or_warn "spool.spark.executor.memory.gb" "6"
check_or_warn "spool.spark.executor.memory.overhead.gb" "1"
check_or_warn "spool.spark.driver.memory.gb" "4"
check_or_warn "spool.spark.driver.memory.overhead.gb" "0"
check_or_warn "spool.spark.worker.memory.gb" "7"
check_or_warn "spool.spark.worker.cores" "2"
check_or_warn "spool.spark.local.dirs" "$TMP_DIR"
check_or_warn "spool.spark.log.dir" "$LOG_DIR"
check_or_warn "spool.spark.gc.opts" "-XX:+UseParallelGC -XX:+UseParallelOldGC"
check_or_warn "spool.spark.daemon.memory" "6G"
check_or_warn "spool.spark.daemon.java.opts" "-XX:+UseParallelGC -XX:+UseParallelOldGC"
check_or_warn "spool.spark.log.maxfiles" "10"
check_or_warn "spool.spark.log.maxsize" "100M"
check_or_warn "spool.spark.event_log.enabled" "false"
check_or_warn "spool.spark.history_log.enabled" "false"

if [ $missing_fields -eq 1 ]; then
    echo "⚡ Some fields were missing. Updated and will overwrite config."
fi

# Manually enforce key paths
conf_map["spool.spark.log.dir"]="$LOG_DIR"
conf_map["spool.spark.local.dirs"]="$TMP_DIR"

# 4. Save corrected config back
{
  for key in "${!conf_map[@]}"; do
    echo "$key=${conf_map[$key]}"
  done
  # Interpolate ${CONTEXT_ID} in values
} > "$CONF_DIR/spool-spark-default.conf"

# 5. Print effective config for debug
echo "==== Final Effective Spool Config ===="
cat "$CONF_DIR/spool-spark-default.conf"
echo "======================================="

# 6. Assemble spark-env.sh
cat > "$CONF_DIR/spark-env.sh" <<EOF
#!/usr/bin/env bash
# Auto-generated spark-env.sh for context $CONTEXT_ID

export SPARK_EXECUTOR_MEMORY="${conf_map["spool.spark.executor.memory.gb"]}g"
export SPARK_EXECUTOR_MEMORY_OVERHEAD="${conf_map["spool.spark.executor.memory.overhead.gb"]}g"
export SPARK_DRIVER_MEMORY="${conf_map["spool.spark.driver.memory.gb"]}g"
export SPARK_DRIVER_MEMORY_OVERHEAD="${conf_map["spool.spark.driver.memory.overhead.gb"]}g"
export SPARK_WORKER_MEMORY="${conf_map["spool.spark.worker.memory.gb"]}g"
export SPARK_WORKER_CORES="${conf_map["spool.spark.worker.cores"]}"
export SPARK_LOCAL_DIRS="${conf_map["spool.spark.local.dirs"]}"
export SPARK_LOG_DIR="${conf_map["spool.spark.log.dir"]}"
export SPARK_LOG_MAXFILES="${conf_map["spool.spark.log.maxfiles"]}"
export SPARK_LOG_MAXSIZE="${conf_map["spool.spark.log.maxsize"]}"
export SPARK_GC_OPTS="${conf_map["spool.spark.gc.opts"]}"
export SPARK_DAEMON_MEMORY="${conf_map["spool.spark.daemon.memory"]}"
export SPARK_DAEMON_JAVA_OPTS="${conf_map["spool.spark.daemon.java.opts"]}"
EOF

chmod +x "$CONF_DIR/spark-env.sh"

# 7. Assemble spark-defaults.conf
cat > "$CONF_DIR/spark-defaults.conf" <<EOF
# Auto-generated spark-defaults.conf for context $CONTEXT_ID

spark.executor.memory ${conf_map["spool.spark.executor.memory.gb"]}g
spark.driver.memory ${conf_map["spool.spark.driver.memory.gb"]}g
spark.eventLog.enabled ${conf_map["spool.spark.event_log.enabled"]}
spark.history.fs.logDirectory file:///dev/null
spark.eventLog.dir file:///dev/null
spark.local.dir ${conf_map["spool.spark.local.dirs"]}
EOF

# 8. Assemble log4j.properties
cat > "$CONF_DIR/log4j.properties" <<EOF
# Auto-generated log4j.properties for context $CONTEXT_ID

log4j.rootCategory=INFO, file
log4j.appender.file=org.apache.log4j.RollingFileAppender
log4j.appender.file.File=${conf_map["spool.spark.log.dir"]}/class.log
log4j.appender.file.MaxFileSize=${conf_map["spool.spark.log.maxsize"]}
log4j.appender.file.MaxBackupIndex=${conf_map["spool.spark.log.maxfiles"]}
log4j.appender.file.layout=org.apache.log4j.PatternLayout
log4j.appender.file.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n
EOF

# 9. Create empty log files
touch "$LOG_DIR/loader.log" "$LOG_DIR/class.log" "$LOG_DIR/stdout.log" "$LOG_DIR/stderr.log"

# 10. Copy corrected spool config into logs (optional inside JVM)
cp "$CONF_DIR/spool-spark-default.conf" "$LOG_DIR/spool-spark-default.conf"

# 11. Save context metadata
cat >> "$CONTEXT_DIR/.spool-env.sh" <<EOF

# Finalizer injected
export SPARK_SPOOL_CONTEXT_LOG_FILE="logs/loader.log"
export SPARK_SPOOL_CONTEXT_SPARK_LOCAL_DIR="$TMP_DIR"
EOF

# 12. Done
echo "✅ Finalized context $CONTEXT_ID:"
echo "   • Conf dir: $CONF_DIR"
echo "   • Logs dir: $LOG_DIR"
echo "   • Scratch dir: $TMP_DIR"
