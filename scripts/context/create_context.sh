#!/usr/bin/env bash
set -euo pipefail

echo "🔨 Creating Gramine Spark Context..."

SPARK_HOME="${1:-/opt/spark}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTEXT_DIR="${1:?Missing context dir argument}"

source "$SCRIPT_DIR/prepare-env.sh"

mkdir -p "$CONTEXT_DIR/opt/spark/jars"
mkdir -p "$CONTEXT_DIR/opt/spark/conf"
mkdir -p "$CONTEXT_DIR/log"
mkdir -p "$CONTEXT_DIR/untrusted-logs"

# -- Copy Jars as symlinks
for jar in "$SPARK_HOME"/jars/*.jar; do
  ln -s "$jar" "$CONTEXT_DIR/opt/spark/jars/"
done

# -- Handle log4j
log4j_path=$(echo "$SPARK_DAEMON_JAVA_OPTS" | grep -oP 'file:\K[^ ]+')
log4j_basename=$(basename "$log4j_path")
log4j_target="$CONTEXT_DIR/opt/spark/conf/$log4j_basename"
mkdir -p "$(dirname "$log4j_target")"
cp "$log4j_path" "$log4j_target"

# -- Patch log4j inside context
logfile_name=$(grep '^log4j.appender.file.File=' "$log4j_target" | cut -d'=' -f2 | xargs basename)
sed -i "s|^log4j.appender.file.File=.*|log4j.appender.file.File=log/$logfile_name|" "$log4j_target"

# -- Create real log files
host_logfile_path="$(dirname "$log4j_path")/$logfile_name"
touch "$host_logfile_path"

# -- Symlinks inside enclave context
ln -s "$host_logfile_path" "$CONTEXT_DIR/log/$logfile_name"
touch "$(dirname "$host_logfile_path")/loader.log"
ln -s "$(dirname "$host_logfile_path")/loader.log" "$CONTEXT_DIR/log/loader.log"

# -- Stdout and stderr
touch "$(dirname "$host_logfile_path")/worker-stdout.log"
touch "$(dirname "$host_logfile_path")/worker-stderr.log"
ln -s "$(dirname "$host_logfile_path")/worker-stdout.log" "$CONTEXT_DIR/untrusted-logs/worker-stdout.log"
ln -s "$(dirname "$host_logfile_path")/worker-stderr.log" "$CONTEXT_DIR/untrusted-logs/worker-stderr.log"

# Copy /opt/spark/bin into the context
mkdir -p "$CONTEXT_DIR/opt/spark"
ln -s /opt/spark/bin "$CONTEXT_DIR/opt/spark/bin"
# Copy manifest template
cp "${SCRIPT_DIR}/java.manifest.template" "${CONTEXT_DIR}/java.manifest.template"

# Optional: Check success
if [[ ! -f "${CONTEXT_DIR}/java.manifest.template" ]]; then
    echo "❌ Failed to copy manifest template!"
    exit 1
fi
echo "✅ Copied manifest template to context."
echo "�~\~E Context created at $CONTEXT_DIR"
