#!/usr/bin/env bash
set -euo pipefail

CONTEXT_DIR="${1:?Context directory not provided}"

# Source Spark env
if [ ! -f "$CONTEXT_DIR/spark-env.sh" ]; then
    echo "❌ Missing spark-env.sh in $CONTEXT_DIR"
    exit 1
fi
source "$CONTEXT_DIR/spark-env.sh"

# Source Gramine env
if [ ! -f "$CONTEXT_DIR/gramine-env.sh" ]; then
    echo "❌ Missing gramine-env.sh in $CONTEXT_DIR"
    exit 1
fi
source "$CONTEXT_DIR/gramine-env.sh"

# === Fill missing Spark variables with defaults ===
SPARK_MASTER_HOST="${SPARK_MASTER_HOST:-127.0.0.1}"
SPARK_HOME="/opt/spark"
SPARK_EXECUTOR_MEMORY_GB="${SPARK_EXECUTOR_MEMORY_GB:-6}"
SPARK_EXECUTOR_MEMORY_OVERHEAD_GB="${SPARK_EXECUTOR_MEMORY_OVERHEAD_GB:-1}"
SPARK_WORKER_MEMORY_GB="${SPARK_WORKER_MEMORY_GB:-7}"
SPARK_WORKER_CORES="${SPARK_WORKER_CORES:-2}"
SPARK_DRIVER_MEMORY_GB="${SPARK_DRIVER_MEMORY_GB:-4}"
SPARK_DRIVER_MEMORY_OVERHEAD_GB="${SPARK_DRIVER_MEMORY_OVERHEAD_GB:-0}"
SPARK_DAEMON_MEMORY="${SPARK_DAEMON_MEMORY:-6g}"
SPARK_GC_OPTS="${SPARK_GC_OPTS:-"-XX:+UseParallelGC -XX:+UseParallelOldGC"}"
SPARK_LOG_LEVEL="${SPARK_LOG_LEVEL:-INFO}"
SPARK_MASTER_PORT="${SPARK_MASTER_PORT:-7077}"
SPARK_MASTER_WEBUI_PORT="${SPARK_MASTER_WEBUI_PORT:-8080}"
SPARK_LOG_MAXFILES="${SPARK_LOG_MAXFILES:-10}"
SPARK_LOG_MAXSIZE="${SPARK_LOG_MAXSIZE:-100m}"

# === Critical Spark variables that must exist ===
required_critical_spark_vars=(
    SPARK_LOG_DIR
    SPARK_DAEMON_JAVA_OPTS
)

for var in "${required_critical_spark_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "❌ Missing critical Spark variable: $var"
        exit 1
    fi
done

# === Fill missing Gramine variables with safe defaults ===
SPARK_SPOOL_STACK_SIZE="${SPARK_SPOOL_STACK_SIZE:-1M}"        # Safe stack
SPARK_SPOOL_BRK_SIZE="${SPARK_SPOOL_BRK_SIZE:-1M}"             # Safe brk
SPARK_SPOOL_LOADER_LOG_LEVEL="${SPARK_SPOOL_LOADER_LOG_LEVEL:-error}"
SPARK_SPOOL_LOADER_LOG_FILE="${SPARK_SPOOL_LOADER_LOG_FILE:-loader.log}"
SPARK_SPOOL_FDS_LIMIT="${SPARK_SPOOL_FDS_LIMIT:-2048}"

# === Critical Gramine variables that must exist ===
required_critical_gramine_vars=(
    SPARK_SPOOL_ENCLAVE_THREADS
    SPARK_SPOOL_EDMM
    SPARK_SPOOL_ENABLE_SIGTERM
    SPARK_SPOOL_INSECURE_DISABLE_ASLR
    SPARK_SPOOL_DISALLOW_SUBPROCESS
    SGX_ENCLAVE_SIZE
)

for var in "${required_critical_gramine_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "❌ Missing critical Gramine variable: $var"
        exit 1
    fi
done

find_free_port() {
    local start_port=$1
    local end_port=$2

    for port in $(seq "$start_port" "$end_port"); do
        if ! ss -ltn "( sport = :$port )" | grep -q .; then
            if [[ "$port" != "$SPARK_MASTER_PORT" && "$port" != "$SPARK_MASTER_WEBUI_PORT" ]]; then
                echo "$port"
                return 0
            fi
        fi
    done
    return 1
}

# Default to finding free port starting from 8080 if not manually set
if [[ -z "${SPARK_WORKER_WEBUI_PORT:-}" ]]; then
    echo "🌐 SPARK_WORKER_WEBUI_PORT not set. Searching for free port starting from 8080..."
    found_port=$(find_free_port 8081 8099) || {
        echo "❌ Could not find free WebUI port between 8080-8099."
        exit 1
    }
    export SPARK_WORKER_WEBUI_PORT="$found_port"
    echo "✅ Using WebUI port: $SPARK_WORKER_WEBUI_PORT"
fi

export SPARK_SCALA_VERSION=2.12

# === Save validated environment ===
cat > "$CONTEXT_DIR/.spark_spool_env" <<EOF
export SPARK_SCALA_VERSION="$SPARK_SCALA_VERSION"
export SAPRK_HOME="/opt/spark"
export SPARK_MASTER_HOST="$SPARK_MASTER_HOST"
export SPARK_EXECUTOR_MEMORY_GB="$SPARK_EXECUTOR_MEMORY_GB"
export SPARK_EXECUTOR_MEMORY_OVERHEAD_GB="$SPARK_EXECUTOR_MEMORY_OVERHEAD_GB"
export SPARK_WORKER_MEMORY_GB="$SPARK_WORKER_MEMORY_GB"
export SPARK_HOME="$SPARK_HOME"
export SPARK_WORKER_CORES="$SPARK_WORKER_CORES"
export SPARK_DRIVER_MEMORY_GB="$SPARK_DRIVER_MEMORY_GB"
export SPARK_DRIVER_MEMORY_OVERHEAD_GB="$SPARK_DRIVER_MEMORY_OVERHEAD_GB"
export SPARK_DAEMON_MEMORY="$SPARK_DAEMON_MEMORY"
export SPARK_GC_OPTS="$SPARK_GC_OPTS"
export SPARK_LOG_DIR="$SPARK_LOG_DIR"
export SPARK_LOG_LEVEL="$SPARK_LOG_LEVEL"
export SPARK_MASTER_PORT="$SPARK_MASTER_PORT"
export SPARK_MASTER_WEBUI_PORT="$SPARK_MASTER_WEBUI_PORT"
export SPARK_WORKER_WEBUT_PORT="$SPARK_WORKER_WEBUT_PORT"
export SPARK_LOG_MAXFILES="$SPARK_LOG_MAXFILES"
export SPARK_LOG_MAXSIZE="$SPARK_LOG_MAXSIZE"
export SPARK_DAEMON_JAVA_OPTS="$SPARK_DAEMON_JAVA_OPTS"

export SPARK_SPOOL_STACK_SIZE="$SPARK_SPOOL_STACK_SIZE"
export SPARK_SPOOL_BRK_SIZE="$SPARK_SPOOL_BRK_SIZE"
export SPARK_SPOOL_LOADER_LOG_LEVEL="$SPARK_SPOOL_LOADER_LOG_LEVEL"
export SPARK_SPOOL_LOADER_LOG_FILE="$SPARK_SPOOL_LOADER_LOG_FILE"
export SPARK_SPOOL_FDS_LIMIT="$SPARK_SPOOL_FDS_LIMIT"

export SPARK_SPOOL_ENCLAVE_THREADS="$SPARK_SPOOL_ENCLAVE_THREADS"
export SPARK_SPOOL_EDMM="$SPARK_SPOOL_EDMM"
export SPARK_SPOOL_ENABLE_SIGTERM="$SPARK_SPOOL_ENABLE_SIGTERM"
export SPARK_SPOOL_INSECURE_DISABLE_ASLR="$SPARK_SPOOL_INSECURE_DISABLE_ASLR"
export SPARK_SPOOL_DISALLOW_SUBPROCESS="$SPARK_SPOOL_DISALLOW_SUBPROCESS"
export SGX_ENCLAVE_SIZE="$SGX_ENCLAVE_SIZE"
EOF

echo "Env is built succesfully"
