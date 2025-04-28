SHELL := /bin/bash
THIS_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
CONTEXT_DIR ?= 
MANIFEST_MAKEFILE := $(CONTEXT_DIR)/Makefile.manifest

PREPARE_ENV_SCRIPT := $(THIS_DIR)/prepare-env.sh
CREATE_CONTEXT_SCRIPT := $(THIS_DIR)/create_context.sh
SPARK_CLASS_WRAPPER_SCRIPT := $(THIS_DIR)/../launch/print-spark-cmd.bash

.PHONY: all prepare-env create-context manifest clean distclean show-cmd

# === Main flow ===
all: prepare-env create-context manifest

prepare-env:
	$(PREPARE_ENV_SCRIPT) $(CONTEXT_DIR)

create-context:
	$(CREATE_CONTEXT_SCRIPT) $(CONTEXT_DIR)

manifest:
	@if [ ! -d "$(CONTEXT_DIR)" ]; then \
		echo "❌ Context directory '$(CONTEXT_DIR)' not found. Please run create-context first."; \
		exit 1; \
	fi
	@make -C $(CONTEXT_DIR) context-manifest


show-cmd:
	@if [ -z "$(SPARK_MAIN_CLASS)" ]; then \
		echo "❌ SPARK_MAIN_CLASS is not set."; \
		exit 1; \
	fi
	@../launch/print-spark-cmd.bash $(SPARK_MAIN_CLASS) $(SPARK_ARGS)


clean:
	@if [ -d "$(CONTEXT_DIR)" ]; then \
		make -C $(CONTEXT_DIR) clean; \
	else \
		echo "⚠️ Context directory '$(CONTEXT_DIR)' not found, skipping manifest clean."; \
	fi
	rm -rf $(CONTEXT_DIR)/logs $(CONTEXT_DIR)/untrusted-logs $(CONTEXT_DIR)/opt/spark/conf/*

distclean: clean
	@if [ -d "$(CONTEXT_DIR)" ]; then \
		make -C $(CONTEXT_DIR) distclean; \
	else \
		echo "⚠️ Context directory '$(CONTEXT_DIR)' not found, skipping distclean."; \
	fi
	rm -rf $(CONTEXT_DIR)

