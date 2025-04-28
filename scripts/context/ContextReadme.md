 README
Welcome to the created_context/ directory!

This directory manages the runtime context of a Spark Worker inside
a Gramine enclave or native Java environment, without modification.

🏗️ What This Context Does
Builds a minimal isolated filesystem view for a Spark Java process.

Generates a Gramine manifest automatically.

Allows native and Gramine execution of Spark workers identically.

Configures logs, environment, and Java invocation safely.

Detects changes and triggers rebuilds cleanly.

🚦 Major Components
Item	Purpose
opt/	Symlinked Spark binaries, jars, and configs
logs/	Enclave-trusted logs (e.g., log4j file outputs)
untrusted-logs/	Native-only stdout/stderr for monitoring
java.manifest.template	Manifest template with variables
java.manifest	Compiled Gramine manifest
java.manifest.sgx	Signed SGX manifest (optional)
Makefile.manifest	Builds/cleans manifest artifacts
🛠️ How to Build the Context
From project root, simply run:

bash
Copy code
make context
This will:

Parse and validate gramine-env.sh.

Create the enclave/natural context directory.

Copy and rewrite the log4j.properties file properly.

Create and symlink Spark binaries, jars, configs.

Set up stdout/stderr logs.

Compile the Gramine manifest (gramine-manifest).

Sign the manifest (gramine-sgx-sign) if SGX=1.

The resulting environment is ready for:

Running natively with Java

Running inside a Gramine enclave with gramine-direct

📜 Manifest Details
The manifest auto-configures:

libos.entrypoint: Path to java binary

loader.log_level: Based on context

sys.stack.size, sys.brk.max_size: From gramine-env.sh

sgx.enclave_size, sgx.max_threads, sgx.edmm_enable

sgx.use_exinfo, sgx.allowed_files, sgx.trusted_files

Correct environment variables like SPARK_HOME, SPARK_WORKER_CORES, etc.

Special options:

Disable ASLR if needed.

Allow external SIGTERM for graceful shutdown.

Explicitly disallow/allow subprocesses.

Loader and Spark logs are separated cleanly.

🚨 Important Behavior
If the context is not fully created, make will fail cleanly.

Multiple contexts can exist at once (for multiple workers).

Context reuses Spark environment but locks trusted files against tampering.

Native and Gramine runs behave the same inside the context.

Gramine will only trust exact symlinks — no writable jars or configs.

🐛 Debugging Aids
After make context, prints all environment variables.

Dumps rewritten log4j.properties into context.

Shows the full Java CMD extracted via patched spark-class.

Clearly highlights if trusted files are missing.

Clean separation of trusted vs untrusted logs.

High verbosity when DEBUG=1 is set.

🧹 Cleanup Targets
bash
Copy code
make clean
Deletes all compiled manifests, signatures, tokens.

bash
Copy code
make distclean
Destroys the entire created context.

Deletes all logs, symlinks, binaries under created_context/.

📋 Special Notes
No Docker assumptions — designed for direct VM or bare-metal SGX.

Respects EDMM mode for SGX enclaves if available.

Designed as part of the weave-artifacts family but works standalone for Spark-Gramine research.

🎯 Next Step: Testing!
✅ Context creation?
✅ Manifest generation?
✅ Logs and symlinks ready?

🔜 Now we can run controlled tests to validate enclave and native Spark worker startup!


