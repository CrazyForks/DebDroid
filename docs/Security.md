# Security Implications

## Vulnerabilities

Most of the older Android devices supported by DebDroid have already reached end‑of‑life (EOL), meaning they no longer receive security patches or kernel updates. That means any vulnerabilities discovered past their last system update remain unpatched, making these environments unsuitable for handling confidential data or production-grade workloads. DebDroid is intended for tasks where exposing personal information is not a concern.

## RNG and Cryptography

This project patches certain system utilities, providing compatibility with the Android system by overriding Linux's randomness mechanisms, such as the `getrandom` syscall, `getentropy` function and glibc’s `arc4random` functions. It replaces the default cryptographic randomness with direct `/dev/urandom` reads. This is generally safe on modern Linux/Android, because the kernel ensures `/dev/urandom` provides high-quality entropy.
