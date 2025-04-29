SPARK_HOME ?= /opt/spark
SPARK_SPOOL_CONTEXT_MAINDIR ?= /tmp/spool-contexts

CONTEXT_DIR := $(SPARK_SPOOL_CONTEXT_MAINDIR)/$(CONTEXT_ID)

# Files
MANIFEST_TEMPLATE := $(CONTEXT_DIR)/template.manifest
MANIFEST_OUT := $(CONTEXT_DIR)/manifest
SPARK_SPOOL_CONF ?= $(SPARK_HOME)/conf/spool-spark-default.conf
SPARK_SPOOL_MANIFEST_TEMPLATE ?= $(SPARK_HOME)/conf/spark.manifest.template

# Load config
include $(SPARK_SPOOL_CONF)

ifeq ($(MODE),native)
all:
	@echo "✅ Native mode selected, skipping manifest creation."
else
all: $(MANIFEST_OUT)
ifeq ($(MODE),sgx)
all: $(MANIFEST_OUT).sgx $(MANIFEST_OUT).sig
endif
endif

# Step 1: Copy manifest template into context
$(MANIFEST_TEMPLATE):
	@echo "📋 Copying spark.manifest.template into context $(CONTEXT_ID)..."
	cp $(SPARK_SPOOL_MANIFEST_TEMPLATE) $(MANIFEST_TEMPLATE)

# Step 2: Generate manifest
$(MANIFEST_OUT): $(MANIFEST_TEMPLATE)
	@echo "🔧 Building manifest for context $(CONTEXT_ID)..."
	cd $(CONTEXT_DIR) && gramine-manifest \
		-Darch_libdir=$(ARCH_LIBDIR) \
		-Dentrypoint=$(ENTRYPOINT) \
		-Dloader_log_level=$(spool.loader.log_level) \
		-Dstack_size=$(spool.stack.size) \
		-Dbrk_size=$(spool.brk.size) \
		-Denable_sigterm=$(spool.enable.sigterm) \
		-Ddisable_aslr=$(spool.disable.aslr) \
		-Ddisallow_subprocesses=$(spool.disallow.subprocesses) \
		-Dsgx_enclave_size=$(spool.sgx.enclave_size) \
		-Dsgx_max_threads=$(spool.sgx.max_threads) \
		-Dsgx_edmm_enable=$(spool.sgx.edmm_enable) \
		-Dspark_home=$(SPARK_HOME) \
		-Dcontext_id=$(CONTEXT_ID) \
		$(notdir $(MANIFEST_TEMPLATE)) > $(notdir $(MANIFEST_OUT))

# Step 3: Sign for SGX
$(MANIFEST_OUT).sgx $(MANIFEST_OUT).sig: $(MANIFEST_OUT)
	@echo "🔐 Signing manifest for SGX mode..."
	cd $(CONTEXT_DIR) && gramine-sgx-sign \
		--manifest $(notdir $(MANIFEST_OUT)) \
		--output $(notdir $(MANIFEST_OUT)).sgx
