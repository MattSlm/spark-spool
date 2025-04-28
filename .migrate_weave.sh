#!/bin/bash
set -euo pipefail

# =====================================
# ⚡ TEMPORARY MIGRATION SCRIPT
# - Copy everything relevant from weave-artifacts/examples/spark/
# - Touch missing scripts
# - Move old README files under docs/
# =====================================

SRC_DIR="/opt/git/weave-artifacts/examples/spark"
DEST_DIR="/opt/git/spark-spool"

mkdir -p "$DEST_DIR/scripts"
mkdir -p "$DEST_DIR/contexts"
mkdir -p "$DEST_DIR/manifests"
mkdir -p "$DEST_DIR/examples"
mkdir -p "$DEST_DIR/docs"

echo "🔄 Copying Spark scripts..."
cp -a "$SRC_DIR/scripts/"* "$DEST_DIR/scripts/" || true

echo "🔄 Copying example tests..."
cp -a "$SRC_DIR/examples/"* "$DEST_DIR/examples/" || true

echo "🔄 Copying manifests (if any)..."
cp -a "$SRC_DIR/manifests/"* "$DEST_DIR/manifests/" || true

echo "📚 Moving README and docs to docs/ ..."
find "$SRC_DIR" -maxdepth 1 -iname "*readme*" -exec cp {} "$DEST_DIR/docs/" \; || true

echo "📄 Touching missing placeholder files..."

# Touch basic Makefile if missing
if [[ ! -f "$DEST_DIR/Makefile" ]]; then
  touch "$DEST_DIR/Makefile"
  echo "ℹ️  Created placeholder Makefile"
fi

# Touch gramine-manifest.template if missing
if [[ ! -f "$DEST_DIR/manifests/gramine-manifest.template" ]]; then
  touch "$DEST_DIR/manifests/gramine-manifest.template"
  echo "ℹ️  Created placeholder manifest template"
fi

# Touch base README if missing
if [[ ! -f "$DEST_DIR/README.md" ]]; then
  touch "$DEST_DIR/README.md"
  echo "ℹ️  Created placeholder README.md"
fi

echo "✅ Migration completed!"
echo "👉 Now manually review and clean the imported files."

