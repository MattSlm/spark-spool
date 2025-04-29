# Top-level Makefile for Spark Spool

REPO_ROOT := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
DEPS_DIR := $(REPO_ROOT)/deps
CONTEXT_DIR := $(REPO_ROOT)/context
TEST_DIR := $(REPO_ROOT)/test

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

parse-deps:
	@echo "📦 Parsing dependencies and creating lockfile..."
	@bash $(DEPS_DIR)/parse-system-deps.sh

install-deps:
	@echo "📦 Installing packages from lockfile..."
	@bash $(DEPS_DIR)/install-deps-from-lock.sh

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

install-spool-config: check-deps
	@echo "🔧 Installing spool-spark-default.conf and spark.manifest.template to $(SPARK_HOME)/conf/..."
	@if [ ! -d "$(SPARK_HOME)/conf" ]; then \
		echo "❌ SPARK_HOME $(SPARK_HOME)/conf not found!"; \
		exit 1; \
	fi
	@if [ ! -f "$(SPARK_HOME)/conf/spark-defaults.conf" ]; then \
		echo "⚠️ WARNING: spark-defaults.conf not found!"; \
		echo "👉 Please create it manually:"; \
		echo "    cp spark-defaults.conf.template spark-defaults.conf"; \
	fi
	@if [ ! -f "$(SPARK_HOME)/conf/log4j.properties" ]; then \
		echo "⚠️ WARNING: log4j.properties not found!"; \
		echo "👉 Please create it manually:"; \
		echo "    cp log4j.properties.template log4j.properties"; \
	fi
	@cp spool-spark-default.conf $(SPARK_HOME)/conf/
	@cp spark.manifest.template $(SPARK_HOME)/conf/
	@echo "✅ spool-spark-default.conf installed to $(SPARK_HOME)/conf/"
	@echo "✅ spark.manifest.template installed to $(SPARK_HOME)/conf/"

# Group dependency ops
deps: parse-deps install-deps check-deps

# ========================
# Context Management
# ========================

create_context:
	@echo "🛠️ Creating context $(CONTEXT_ID)..."
	SPARK_SPOOL_CONTEXT_MAINDIR=$(SPARK_SPOOL_CONTEXT_MAINDIR) \
	bash $(CONTEXT_DIR)/create_context.sh $(CONTEXT_ID) $(CLASS) $(CLASS_ARGS)

finalize_context:
	@echo "🛠️ Finalizing context $(CONTEXT_ID)..."
	SPARK_SPOOL_CONTEXT_MAINDIR=$(SPARK_SPOOL_CONTEXT_MAINDIR) \
	SPARK_HOME=$(SPARK_HOME) \
	bash $(CONTEXT_DIR)/finalize_context.sh $(CONTEXT_ID) $(LOG_LEVEL)

build_manifest:
	@echo "🛠️ Building manifest for context $(CONTEXT_ID) in mode $(MODE)..."
	@$(MAKE) -C $(CONTEXT_DIR) -f Makefile.manifest CONTEXT_ID=$(CONTEXT_ID) MODE=$(MODE) SPARK_HOME=$(SPARK_HOME)

# ========================
# Cleaning Targets
# ========================

clean:
	@echo "🧹 Cleaning context artifacts (future work)..."
	@# Example: rm -rf $(SPARK_SPOOL_CONTEXT_MAINDIR)/*

distclean: clean
	@echo "🔥 Fully cleaning lockfiles and setup artifacts..."
	@rm -f $(LOCKFILE)
	@rm -f $(REPO_SETUP)
