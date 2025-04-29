#!/bin/bash
set -euo pipefail

# Usage:
# ./create-context.sh <ContextID> <Class> [ClassArgs] [Optional: --spool-config /path/to/spool.conf]

CONTEXT_ID="${1:-}"
CLASS="${2:-}"
CLASS_ARGS="${3:-}"
USER_SPOOL_CONFIG="${4:-}"

SPARK_SPOOL_CONTEXT_MAINDIR="${SPARK_SPOOL_CONTEXT_MAINDIR:-/tmp/spool-contexts}"
SPARK_HOME="${SPARK_HOME:-}"

# Safety: Generate CONTEXT_ID if missing
if [ -z "$CONTEXT_ID" ]; then
    CONTEXT_ID="context-$(date +%Y%m%d_%H%M%S)_$RANDOM"
    echo "⚡ Context ID not provided. Generated CONTEXT_ID=$CONTEXT_ID"
fi

# Safety: Set SPARK_HOME fallback
if [ -z "$SPARK_HOME" ]; then
    if [ -d "/opt/spark" ]; then
        SPARK_HOME="/opt/spark"
        echo "⚡ SPARK_HOME not set, defaulting to /opt/spark"
    else
        echo "❌ SPARK_HOME not set and /opt/spark not found. Exiting."
        exit 1
    fi
fi

CONTEXT_DIR="$SPARK_SPOOL_CONTEXT_MAINDIR/$CONTEXT_ID"
CONTEXT_CONF_DIR="$SPARK_HOME/conf/$CONTEXT_ID"
CONTEXT_LOG_DIR="$SPARK_HOME/logs/$CONTEXT_ID"
CONTEXT_SCRATCH_DIR="/scratch/$CONTEXT_ID"

echo "🔨 Creating Gramine Spark Context: $CONTEXT_ID"

# 1. Create necessary directories
mkdir -p "$CONTEXT_DIR/output_data"
mkdir -p "$CONTEXT_CONF_DIR"
mkdir -p "$CONTEXT_LOG_DIR"
mkdir -p "$CONTEXT_SCRATCH_DIR"

# 2. Handle spool-spark-default.conf
if [ -n "$USER_SPOOL_CONFIG" ]; then
    echo "⚡ Using user-provided spool config: $USER_SPOOL_CONFIG"
    cp "$USER_SPOOL_CONFIG" "$CONTEXT_CONF_DIR/spool-spark-default.conf"
else
    if [ ! -f "$SPARK_HOME/conf/spool/spool-spark-default.conf" ]; then
        echo "❌ Default spool config not found at $SPARK_HOME/conf/spool/spool-spark-default.conf"
        exit 1
    fi
    cp "$SPARK_HOME/conf/spool/spool-spark-default.conf" "$CONTEXT_CONF_DIR/spool-spark-default.conf"
    echo "⚡ Using default spool config for context."
fi

# 3. Copy fallback templates for spark-env.sh, spark-defaults.conf, log4j.properties
if [ ! -f "$SPARK_HOME/conf/spool/spark-env.sh.spool" ]; then
    echo "❌ Missing fallback spark-env.sh.spool template!"
    exit 1
fi
if [ ! -f "$SPARK_HOME/conf/spool/spark-defaults.conf.spool" ]; then
    echo "❌ Missing fallback spark-defaults.conf.spool template!"
    exit 1
fi
if [ ! -f "$SPARK_HOME/conf/spool/log4j.properties.spool" ]; then
    echo "❌ Missing fallback log4j.properties.spool template!"
    exit 1
fi

cp "$SPARK_HOME/conf/spool/spark-env.sh.spool" "$CONTEXT_CONF_DIR/spark-env.sh"
cp "$SPARK_HOME/conf/spool/spark-defaults.conf.spool" "$CONTEXT_CONF_DIR/spark-defaults.conf"
cp "$SPARK_HOME/conf/spool/log4j.properties.spool" "$CONTEXT_CONF_DIR/log4j.properties"

chmod +x "$CONTEXT_CONF_DIR/spark-env.sh"

# 4. Write initial .spool-env.sh
cat > "$CONTEXT_DIR/.spool-env.sh" <<EOF
export SPARK_SPOOL_CONTEXT_ID="$CONTEXT_ID"
export SPARK_SPOOL_CONTEXT_CLASS="$CLASS"
export SPARK_SPOOL_CONTEXT_CLASS_ARGS="$CLASS_ARGS"
EOF

echo "✅ Created context structure at $CONTEXT_DIR"
echo "   • Conf dir: $CONTEXT_CONF_DIR"
echo "   • Logs dir: $CONTEXT_LOG_DIR"
echo "   • Scratch dir: $CONTEXT_SCRATCH_DIR"
