#!/usr/bin/env bash
# Example gramine-env.sh for Spark Spool

 === Gramine Configuration ===
export GRAMINE_STACK_SIZE="1M"
export GRAMINE_BRK_SIZE="1M"
export GRAMINE_SGX_EDMM="1"             # 1 = Enable EDMM
export GRAMINE_SGX_MAX_THREADS="16"     # Lower threads if EDMM is enabled
export GRAMINE_SGX_ENCLAVE_SIZE="4G"
export GRAMINE_LOG_LEVEL="error"        # none|error|warning|debug|trace|all
export GRAMINE_FDS_LIMIT="4096"
export SPARK_CONF_DIR="/opt/spark/conf"
export SPARK_HOME="/opt/spark"

echo "✅ Loaded sample gramine-env!"

