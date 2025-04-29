📚 Spool-Spark Configuration Reference
This document describes all the configuration fields available in spool-spark-default.conf.

Each context gets its own spool-spark-default.conf at $SPARK_HOME/conf/<ContextID>/spool-spark-default.conf.
Spool uses this file to:

Tune Spark startup.

Tune Gramine manifest generation.

Control JVM tuning.

Control logging and runtime behavior.

All fields are optional; Spool applies safe defaults if not specified.

🛠 Manifest Configuration (Gramine Layer)
Field	Default	Applies To	Description
spool.loader.log_level	error	manifest	Gramine loader verbosity (error, warning, info, debug)
spool.loader.log_file	loader.log	manifest	Path to loader log file (inside enclave view)
spool.stack.size	2M	manifest	Stack size per thread (e.g., 1M, 2M)
spool.brk.size	512M	manifest	Heap (malloc) size maximum
spool.fds_limit	4096	manifest	Maximum number of file descriptors
spool.enable.sigterm	true	manifest	Allow handling of SIGTERM inside enclave
spool.disable.aslr	false	manifest	Disable address randomization
spool.disallow.subprocesses	false	manifest	Forbid fork/exec inside enclave
spool.sgx.edmm_enable	true	manifest	Enable dynamic paging (EDMM)
spool.sgx.max_threads	256	manifest	Max concurrent threads inside enclave
spool.sgx_enclave_size	4G	manifest	Total memory available to enclave
spool.arch_libdir	/lib/x86_64-linux-gnu	manifest	Architecture-specific library path
spool.entrypoint	/usr/lib/jvm/java-11-openjdk-amd64/bin/java	manifest	Java binary to run inside enclave
🛠 Spark JVM Configuration
Field	Default	Applies To	Description
spool.spark.executor.memory.gb	6	spark-env.sh, spark-defaults.conf	Executor memory size
spool.spark.executor.memory.overhead.gb	1	spark-env.sh	Executor overhead memory
spool.spark.driver.memory.gb	4	spark-env.sh, spark-defaults.conf	Driver memory size
spool.spark.driver.memory.overhead.gb	0	spark-env.sh	Driver overhead memory
spool.spark.worker.memory.gb	7	spark-env.sh	Worker total memory
spool.spark.worker.cores	2	spark-env.sh	Number of cores per worker
spool.spark.master.port	7077	spark-env.sh, spark-defaults.conf	Spark master service port
spool.spark.master.webui.port	random	spark-env.sh, spark-defaults.conf	Spark master WebUI port
spool.spark.local.dirs	/scratch/{context_id}	spark-env.sh, spark-defaults.conf	Spark temporary file dirs
spool.spark.log.dir	logs/{context_id}	spark-env.sh	Spark daemon log dir
spool.spark.log.maxfiles	10	spark-env.sh	Maximum number of rotated log files
spool.spark.log.maxsize	100m	spark-env.sh	Maximum size per log file before rotation
spool.spark.gc.opts	-XX:+UseParallelGC -XX:+UseParallelOldGC	spark-env.sh	JVM GC options
spool.spark.daemon.memory	6g	spark-env.sh	Memory for Spark daemons
spool.spark.daemon.java.opts	-XX:+UseParallelGC -XX:+UseParallelOldGC	spark-env.sh	Extra Java opts for daemons
🛠 Logging and Behavior Control
Field	Default	Applies To	Description
spool.spark.event_log.enabled	false	spark-defaults.conf	Enable Spark event logs (true/false)
spool.spark.history_log.enabled	false	spark-defaults.conf	Enable Spark history logs (true/false)
📋 Important Notes
If spool.spark.master.webui.port is not specified, a free random port will be selected during context finalization.

All memory fields must be specified in GB units (integer).

Stack size, brk size must specify units like M, G if not default MiB.

JVM GC options and daemon memory can be customized, but Spark defaults are safe for enclaves.

✅ Spool ensures consistency: if you set memory or cores in spool-spark-default.conf, Spark configs are generated accordingly.

✅ No need to manually edit spark-env.sh or spark-defaults.conf.

