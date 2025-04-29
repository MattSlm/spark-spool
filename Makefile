# Top-level Makefile for Spark Spool

REPO_ROOT := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
SCRIPTS_DIR := $(REPO_ROOT)/scripts
DEPS_DIR := $(REPO_ROOT)/deps

LOCKFILE := $(DEPS_DIR)/system-deps.lock
REPO_SETUP := $(DEPS_DIR)/deps-setup.sh

# SPARK configuration
SPARK_HOME ?= /opt/spark
SPARK_SPOOL_CONTEXT_MAINDIR ?= /tmp/spool-contexts

.PHONY: all deps parse-deps install-deps check-deps install-spool-config create_context finalize_context build_manifest clean distclean

# Default goal
all: deps install-spool-config

# ========================
# Dependency Management
# ========================

# Step 1: Parse system-deps.yaml and create lockfile
parse-deps:
	@echo "📦 Parsing dependencies and creating lockfile..."
	@bash $(SCRIPTS_DIR)/deps/parse-system-deps.sh

# Step 2: Install dependencies from lockfile
install-deps:
	@echo "📦 Installing packages from lockfile..."
	@bash $(SCRIPTS_DIR)/deps/install-deps-from-lock.sh

# Step 3: Check if dependencies are already installed
check-deps:
	@echo "🔍 Checking if all system dependencies are installed..."
	@if [ ! -f "$(LOCKFILE)" ]; then \
		echo "❌ Lockfile $(LOCKFILE) not found. Run 'make parse-deps' first."; \
		exit 1; \
	fi
	@missing=0; \
	while read -r pkg; do \
		if ! dpkg -s "$$pkg" >/dev/null 2>&1; then \
			echo "❌ Missing package: $$pkg"; \
			missing=1; \
		fi; \
	done < "$(LOCKFILE)"; \
	if [ "$$missing" -eq 1 ]; then \
		echo "⚠️ Some dependencies are missing."; \
		exit 1; \
	else \
		echo "✅ All dependencies are installed."; \
	fi

# Step 4: Install spool configs into Spark conf dir
install-spool-config: check-deps
	@echo "🔧 Installing spool-spark-default.conf and spark.manifest.template to $(SPARK_HOME)/conf/..."
	@if [ ! -d "$(SPARK_HOME)/conf" ]; then \
		echo "❌ SPARK_HOME $(SPARK_HOME)/conf not found!"; \
		exit 1; \
	fi
	@cp localconf/spool-spark-default.conf $(SPARK_HOME)/conf/
	@cp localconf/spark.manifest.template $(SPARK_HOME)/conf/
	@echo "✅ spool-spark-default.conf installed to $(SPARK_HOME)/conf/"
	@echo "✅ spark.manifest.template installed to $(SPARK_HOME)/conf/"

# Group deps operations
deps: parse-deps install-deps check-deps install-spool-config

# ========================
# Context Management
# ========================

# Create a new context
create_context:
	@echo "🛠️ Creating context $(CONTEXT_ID)..."
	SPARK_SPOOL_CONTEXT_MAINDIR=$(SPARK_SPOOL_CONTEXT_MAINDIR) \
	bash $(SCRIPTS_DIR)/context/create_context.sh $(CONTEXT_ID) $(CLASS) $(CLASS_ARGS)

# Finalize a context (set confs, logs, ports, etc.)
finalize_context:
	@echo "🛠️ Finalizing context $(CONTEXT_ID)..."
	SPARK_SPOOL_CONTEXT_MAINDIR=$(SPARK_SPOOL_CONTEXT_MAINDIR) \
	SPARK_HOME=$(SPARK_HOME) \
	bash $(SCRIPTS_DIR)/context/finalize_context.sh $(CONTEXT_ID) $(LOG_LEVEL)

# Build manifest for a context (for Gramine)
build_manifest:
	@echo "🛠️ Building manifest for context $(CONTEXT_ID) in mode $(MODE)..."
	@$(MAKE) -C $(SCRIPTS_DIR)/context -f Makefile.manifest CONTEXT_ID=$(CONTEXT_ID) MODE=$(MODE)

# ========================
# Cleaning Targets
# ========================

# Clean intermediate artifacts (contexts, manifests, etc.)
clean:
	@echo "🧹 Cleaning context artifacts (to be improved later)..."
	@# Example: rm -rf $(SPARK_SPOOL_CONTEXT_MAINDIR)/*

# Full cleanup: deps + contexts
distclean: clean
	@echo "🔥 Fully cleaning lockfiles and setup scripts..."
	@rm -f $(LOCKFILE)
	@rm -f $(REPO_SETUP)

