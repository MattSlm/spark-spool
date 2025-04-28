# Makefile for Spark Spool

REPO_ROOT := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
SCRIPTS_DIR := $(REPO_ROOT)/scripts
DEPS_DIR := $(REPO_ROOT)/deps
LOCKFILE := $(DEPS_DIR)/system-deps.lock
REPO_SETUP := $(DEPS_DIR)/deps-setup.sh

.PHONY: all deps parse-deps install-deps check-deps clean distclean

# Default goal
all: deps

# Step 1: Parse system-deps.yaml and create lockfile
parse-deps:
	@echo "📦 Parsing dependencies and creating lockfile..."
	@bash $(SCRIPTS_DIR)/parse-system-deps.sh

# Step 2: Install dependencies from lockfile
install-deps:
	@echo "📦 Installing packages from lockfile..."
	@bash $(SCRIPTS_DIR)/install-deps-from-lock.sh

# Combine parse and install into one command
deps: parse-deps install-deps

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
	if [ $$missing -eq 1 ]; then \
		echo "⚠️ Some dependencies are missing."; \
		exit 1; \
	else \
		echo "✅ All dependencies are installed."; \
	fi

# Clean generated contexts (to be implemented later)
clean:
	@echo "🧹 Cleaning contexts (to be implemented)..."
	@# Example: rm -rf context/*

# Full cleanup: deps + contexts
distclean: clean
	@echo "🔥 Fully cleaning deps..."
	rm -f $(LOCKFILE)
	rm -f $(REPO_SETUP)

