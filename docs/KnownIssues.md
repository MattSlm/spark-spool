# Known Issues and TODOs for Running Spark Inside Gramine

## 🧩 Overview

This document tracks the current known limitations, workarounds, and next steps for running Apache Spark under Gramine (SGX/non-SGX). It covers I/O restrictions, logging issues, subprocess limitations, and implications for Web UI/network diagnostics.

---

## ✅ Status

- ✔ SparkPi runs successfully inside Gramine.
- ✔ Hadoop UGI (Kerberos auth) issues resolved via fake `/etc/passwd`.
- ✔ Spark context, UIs, and driver services launch correctly.

---

## 🐛 Known Issues

### 1. `ProcessBuilder("rm")` Fails with ENOMEM
**Symptom:**
java.io.IOException: Cannot run program "rm": error=12, Cannot allocate memory [P1:T2:java] error: failed creating checkpoint: Cannot allocate memory (ENOMEM)

**Root Cause:**
- Spark uses native `rm` via `fork + exec`, which fails because:
  - `fork()` is disallowed or too expensive in enclave context.
  - `/bin/rm` is not trusted (`sgx.trusted_files`).
  - Even if fork is allowed, memory is duplicated for child → heavy overhead.

**Resolution:**
- 🔒 *Do not enable `rm` or fork-heavy ops*.
- ✅ Patch Spark to use Java-based file deletion only (`File.delete()`).
- ✅ Or accept log spam and rely on fallback deletion.

---

### 2. Network Interface Detection Fails
**Symptom:**
java.net.SocketException: ioctl(SIOCGIFCONF) failed

**Impact:**
- Spark Web UI may bind incorrectly.
- MAC generation and hostname logic are affected.
- Netty’s transport layer emits warnings.

**Fix (manifest):**
```toml
sys.ioctl_structs.ifconf = [
  { name = "len", size = 4, direction = "inout" },
  { name = "buf", ptr = [{ size = "len", direction = "inout" }] }
]

sys.allowed_ioctls = [
  { request_code = 0x8912, struct = "ifconf" }, # SIOCGIFCONF
  { request_code = 0x8927 }                    # SIOCGIFHWADDR (optional)
]

4. Java Fork/Exec Creates Checkpoint Errors
Symptom:
[P1:Txx:java] error: failed creating checkpoint: Cannot allocate memory (ENOMEM)

Cause:

Even lightweight subprocesses (python, rm, etc.) crash unless:

sys.disallow_subprocesses = false

Their binaries are sgx.trusted_files.

Decision:

✅ Fork is enabled via manifest.

🚫 Executables are NOT trusted → error.

❗ Allowing fork but blocking exec gives misleading ENOMEM → not true OOM.

Resolution:

Don't rely on subprocesses inside enclave Spark workers.

Consider sandboxing subprocess needs into trusted wrappers.
