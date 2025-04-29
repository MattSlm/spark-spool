# Paths
SPARK_SPOOL_CONTEXT_MAINDIR ?= /tmp/spool-contexts

# Targets
.PHONY: all make_context purge_context

all: make_context

make_context:
	@echo "🔧 Creating context $(CONTEXT_ID)"
	SPARK_SPOOL_CONTEXT_MAINDIR=$(SPARK_SPOOL_CONTEXT_MAINDIR) \
		./create_context.sh $(CONTEXT_ID)

purge_context:
	@echo "🧹 Purging context $(CONTEXT_ID)"
	rm -rf $(SPARK_SPOOL_CONTEXT_MAINDIR)/$(CONTEXT_ID)
