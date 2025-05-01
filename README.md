# 🧵 Spool: Secure Process-Oriented Oblivious Launchpad

Spool is a lightweight, container-oriented launcher for running Apache Spark in Trusted Execution Environments (TEEs) with **minimal enclave overhead**. Designed specifically to support the [Weave](https://github.com/MattSlm/spark-weave-shuffle) system, Spool abstracts away memory-intensive and security-critical components of Spark into carefully isolated execution contexts, enabling practical, secure, and **memory-oblivious** big data shuffling.

---

## 🎯 Goals

Spool aims to:

- ✅ **Enable secure Spark execution** inside enclaves with configurable enclave sizes, I/O, and memory layout.
- 📉 **Minimize overhead** from traditional enclave launch models by pre-generating and reusing context-specific Spark configs.
- 🧠 **Abstract shuffle and state** from Spark workers to protect access patterns and reduce EPC pressure.
- 🤝 **Complement Weave**, a speculative shuffler that ensures oblivious shuffling at scale.

---

## 🔍 What Problems Does Spool Solve?

Running JVM-based distributed analytics (e.g. Spark) inside SGX enclaves is notoriously difficult due to:

- High EPC memory pressure from JVM heap allocation
- Frequent and costly syscalls (especially `fork`, `rm`, `ioctl`)
- Lack of modularity when composing Spark with secure shufflers
- Spark's heavy reliance on shell scripts, subprocesses, and mutable temp files

Spool addresses these by:

- Building **per-context manifest-aware environments** for Spark
- Injecting secure configurations dynamically at enclave build time
- Disabling native file deletion (e.g., `rm`) and falling back to secure Java-based cleanup
- Explicitly controlling enclave memory, ASLR, FDs, and GC options

---

## 🔄 How It Complements Weave

[Weave](https://github.com/MattSlm/spark-weave-shuffle) is a secure and speculative shuffler that provides memory-oblivious data exchanges inside Spark. However, Weave assumes that its surrounding Spark context is:

- Capable of running inside SGX
- Configured to avoid memory leakage via system calls
- Optimized for reduced page swapping and no heap migrations

**Spool delivers this runtime environment**. It offers manifest-level integration, context isolation, and flexible Spark tuning knobs that make it feasible to embed Weave inside real Spark workloads without incurring prohibitive enclave overheads.

Together, **Weave + Spool = Secure, Oblivious, Scalable Spark**.

---

## 🛠 Features

- 🧩 `finalize_context.sh`: Assemble full per-context configs, scratch directories, and manifests
- 🔐 Manifest-driven: control over ASLR, EDMM, enclave size, syscall filtering
- ⚙️ Auto-injection of:
  - `spark-env.sh`
  - `spark-defaults.conf`
  - `log4j.properties`
  - SGX manifest & loader log
- 🗂️ Enclave-aware scratch and log directories (per context)
- 🚫 Controlled subprocess disallowance and syscall filtering (e.g., disabling `/bin/rm`)

---

## 🚀 Getting Started

1. Clone the [Weave repo](https://github.com/MattSlm/spark-weave-shuffle)
2. Follow the Docker or Gramine setup to build the container image
3. Use `scripts/launch_weave_master.sh` or `launch_weave_worker.sh` to create isolated contexts
4. Run your Spark job via `gramine-direct java ...` or spool-mode launcher

---

## 📁 Repo Structure

```
spool/
├── scripts/            # Finalizers, launchers, and testing harness
├── manifests/          # Per-context Gramine manifest templates
├── examples/           # Sample SparkPi jobs and test cases
├── conf/               # spool-spark-default.conf templates
└── README.md           # You are here 🚀
```

---

## 📎 Logo (proposed)

   ______            _
  / __/ /___ ______ (_)__ ___ ___  ___  ___
 _\ \/ __/ // / __/ / / -_) -_) _ \/ _ \/ -_)
/___/\__/\_,_/_/ /_/_/\__/\__/_//_/\___/\__/
```


---

## 📣 Citation / Attribution

If using Spool or Weave in academic or industrial research, please cite our upcoming paper or reference this GitHub repository. For questions, contact [@Mattslm](https://github.com/Mattslm).

---

## 👥 Contributors

Spool is developed and maintained as part of the Weave secure analytics stack by researchers focused on SGX-based distributed systems and secure data processing.

We welcome feedback, issues, and contributions!


