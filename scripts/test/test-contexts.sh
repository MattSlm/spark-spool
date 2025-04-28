#!/usr/bin/env bash
set -euo pipefail

# === Configuration ===
TEST_ROOT="/tmp/spark-spool-tests"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTEXT_SCRIPT_DIR="$SCRIPT_DIR/../context"
SPARK_CLASS_WRAPPER="$CONTEXT_SCRIPT_DIR/../launch/print-spark-cmd.bash"
PREPARE_ENV="$CONTEXT_SCRIPT_DIR/prepare-env.sh"
CREATE_CONTEXT="$CONTEXT_SCRIPT_DIR/create_context.sh"
MAKEFILE="$CONTEXT_SCRIPT_DIR/Makefile"

mkdir -p "$TEST_ROOT"

# === Helper Functions ===

run_test() {
    local test_name="$1"
    local expect_fail="${2:-false}"
    local context_dir="$TEST_ROOT/$test_name"
    local gramine_env="$context_dir/gramine-env.sh"
    local spark_env="$context_dir/spark-env.sh"
    local log4j_conf="$context_dir/log4j.properties"

    echo -e "\n🔵 Running Test: $test_name"
    rm -rf "$context_dir"
    mkdir -p "$context_dir"

    # Create dummy spark-env.sh
    cat > "$spark_env" <<EOF
export SPARK_MASTER_HOST="127.0.0.1"
export SPARK_EXECUTOR_MEMORY_GB=1
export SPARK_EXECUTOR_MEMORY_OVERHEAD_GB=1
export SPARK_WORKER_MEMORY_GB=2
export SPARK_WORKER_CORES=2
export SPARK_DRIVER_MEMORY_GB=1
export SPARK_DRIVER_MEMORY_OVERHEAD_GB=1
export SPARK_DAEMON_MEMORY="2g"
export SGX_ENCLAVE_SIZE="8g"
export SPARK_GC_OPTS="-XX:+UseParallelGC -XX:+UseParallelOldGC"
export SPARK_LOG_DIR="logs/test_logs"
export SPARK_LOG_LEVEL="INFO"
export SPARK_MASTER_PORT="7077"
export SPARK_MASTER_WEBUI_PORT="8080"
export SPARK_LOG_MAXFILES="10"
export SPARK_LOG_MAXSIZE="100m"
export SPARK_DAEMON_JAVA_OPTS="-Dlog4j.configuration=file:$context_dir/log4j.properties -XX:+UseParallelGC -XX:+UseParallelOldGC"
EOF

    # Create dummy gramine-env.sh
    cat > "$gramine_env" <<EOF
export SPARK_SPOOL_ENCLAVE_THREADS=16
export SPARK_SPOOL_STACK_SIZE="1M"
export SPARK_SPOOL_BRK_SIZE="1M"
export SPARK_SPOOL_LOADER_LOG_LEVEL="error"
export SPARK_SPOOL_LOADER_LOG_FILE="loader.log"
export SPARK_SPOOL_EDMM="0"
export SPARK_SPOOL_ENABLE_SIGTERM="1"
export SPARK_SPOOL_INSECURE_DISABLE_ASLR="0"
export SPARK_SPOOL_DISALLOW_SUBPROCESS="0"
export SPARK_SPOOL_FDS_LIMIT=2048
export SPARK_SPOOL_SGX_ENCLAVE_SIZE="4G"
EOF

    # Create dummy log4j.properties
    mkdir -p "$(dirname "$log4j_conf")"
    cat > "$log4j_conf" <<EOF
log4j.rootCategory=INFO, file
log4j.appender.file=org.apache.log4j.RollingFileAppender
log4j.appender.file.File=logs/test_logs/spark-worker.log
log4j.appender.file.MaxFileSize=100MB
log4j.appender.file.MaxBackupIndex=10
log4j.appender.file.layout=org.apache.log4j.PatternLayout
log4j.appender.file.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n
EOF

    pushd "$context_dir" > /dev/null

    export SPARK_ENV="$spark_env"
    export GRAMINE_ENV="$gramine_env"
    export SPARK_CLASS_WRAPPER_PATH="$SPARK_CLASS_WRAPPER"
    export SPARK_HOME="/opt/spark"  # Fake but needed!

    test_pass=true

    if ! make -f "$MAKEFILE" CONTEXT_DIR="$context_dir" prepare-env; then
        test_pass=false
    fi

    if ! make -f "$MAKEFILE" CONTEXT_DIR="$context_dir" create-context; then
        test_pass=false
    fi

    if ! make -f "$MAKEFILE" CONTEXT_DIR="$context_dir" SPARK_MAIN_CLASS="org.apache.spark.deploy.worker.Worker" SPARK_ARGS="spark://127.0.0.1:7777" show-cmd; then
        test_pass=false
    fi

    if ! make -f "$MAKEFILE" CONTEXT_DIR="$context_dir" context-manifest; then
        test_pass=false
    fi

    echo -e "\n📋 Final Environment Variables:"
    env | grep -E 'SPARK_|SPARK_SPOOL_' || true

    popd > /dev/null

    if [[ "$expect_fail" == "false" && "$test_pass" == "true" ]]; then
        echo -e "✅ [PASS] $test_name"
    elif [[ "$expect_fail" == "true" && "$test_pass" == "false" ]]; then
        echo -e "✅ [EXPECTED FAIL] $test_name"
    else
        echo -e "❌ [FAIL] $test_name"
    fi
}

# === Run Tests ===

run_test happy false

# Future failing tests:
# run_test missing_conf true
# run_test broken_log4j true
# run_test invalid_paths true

# === Done ===
echo -e "\n🎯 All tests completed."

