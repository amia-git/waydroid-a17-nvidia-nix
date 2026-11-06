> Translated from Chinese.

# KernelSU Local Manager Build

## Product and identity

- APK：`ksu/out/KernelSU_v3.3.1-28-gb42ad459_32708-local.apk`
- Package name: `me.weishu.kernelsu`; versionName: `v3.3.1-28-gb42ad459`; versionCode: **32708**.
- APK SHA-256：`0126daa41a4e2ac33410c9023bb835666845897b33a6b6035880d81c67239d13`。
- kernel recompiling parameters (see also `ksu/out/expected.txt`:

```text
KSU_EXPECTED_SIZE=0x02ec
KSU_EXPECTED_HASH=d77ee93d9af4c1dbf8b89cf50fd9953db3a61b9142e009a9effeeedb5693eb4f
```

Signing certificate `CN=KernelSU Local Release`, RSA 2048 bit, valid for 10000 days. Keys are located in `ksu/keystore/ksu-local.jks`, passwords and alias are located in `ksu/keystore/README`, both file permissions are measured as **600** and the directory as 700. Please retain keys and passwords for subsequent upgrade to the same signature, and do not submit them to Git or to public.

## Source and Tool Chains

From yay cache clone to `ksu/KernelSU`, local branch `local-manager` is fixed in `b42ad459`. Cloning is not shallow, the whole history contains 2708 submissions; executing `git repack -a -d` and removing inherited objects alternates so that the container can read all history independently.

Read `AGENTS.md`, `justfile`, manager Gradle configuration, and `.github/workflows/build-manager.yml`, `ksud.yml` and Rust environmental scripts.

|Component|Actual version/configuration|
|---|---|
|Containers|rootless Podman, `localhost/ksu-manager-build`; build mirrors based on already existing Ubuntu 22.04|
|JDK|OpenJDK 21.0.12.1 (CI request Java 21)|
|Gradle / AGP / Kotlin|9.7.1 / 9.4.1 / 2.4.20|
|Android SDK|Platform 37.0 r02；compile/target SDK 37；min SDK 31|
|SDK Build Tools / CMake|37.0.0 / 3.22.1|
|Android NDK|r29，29.0.14206865，Clang 21.0.0|
|Rust / Cargo|1.99.1 / 1.99.1，stable|
|ksud target/API|`x86_64-linux-android` / 26|

The submitted CI does not use cargo-ndk: set NDK clang/linker by `.github/scripts/setup-rust-build.sh` and then directly `cargo build`. Cargo updates the working copy lockfile according to the command not added to `--locked` upstream. Manager limits ABI by independent `x86_64.init.gradle` to generate logic or manager code; contains only x86_64. Gradle automatically installs Platform-Tools 37.0.1. The host has not installed the tool chain and does not operate the host internal core module, DKMS or Waydroid.

## Command

Run in project root directory:

```bash
podman build -t localhost/ksu-manager-build -f ksu/Containerfile ksu
podman run --rm -v "$PWD/ksu:/work" localhost/ksu-manager-build bash /work/generate-key.sh
podman run --rm --name ksu-manager-compile \
  -v "$PWD/ksu:/work" -v ksu-gradle-cache:/root/.gradle \
  -v ksu-cargo-cache:/root/.cargo/registry -v ksu-cargo-git:/root/.cargo/git \
  localhost/ksu-manager-build bash /work/build-manager.sh
podman run --rm -v "$PWD/ksu:/work" localhost/ksu-manager-build bash /work/sign-manager.sh
python ksu/apk_certificate.py \
  ksu/out/KernelSU_v3.3.1-28-gb42ad459_32708-local.apk \
  ref/kernelsu/KernelSU_v3.3.1_32680-release.apk
```

`generate-key.sh` Only for the first time. The existing key will not be overridden. Mr. Build command becomes ksud, copying to `jniLibs/x86_64/libksud.so`, executes `assembleRelease`; signature command is completed and signed locally as file key.

## Verification

- Gradle development successfully constructed; `apksigner verify --verbose --print-certs` authenticated, **v2=true**, single signer. Only v2 is enabled, in accordance with the limits of the kernel accepting only v2 and verity padding signature blocks.
- `aapt2 dump badging` Test versionCode **32708**, versionName like upper, native-code **x86_64**. Version formula is `30000 + git rev-list --count HEAD = 30000 + 2708`, consistent with kernel 32708; the Android installation/interface validation has not yet been performed.
- APK contains `lib/x86_64/libksud.so`, `libkernelsu.so` and `libadbroot.so`. Libksud is x86_64 ELF, size 3987096, corresponding to the construction product by bytes after AGP trip; SHA-256 is `9a55b44ea8f00e84a0cfe94ec5589c55bab883170a3d72203cf0f64dbda768db`.
- `ksu/apk_certificate.py` Organisation `kernel/manager/apk_sign.c` , the signature block length/ID check, and the length and SHA-256 of the first DER certificate for the first signer at v2  →  signed Data  →  certificates ; the local APK gets the above-line parameters.
- The same parser for official `KernelSU_v3.3.1_32680-release.apk` gets **0x033b** and **c371061b19d8c7d7d6133c6a9bafe198fa944e50c1b31c9d8daa8d7f1fc2d2d6**, exactly as expected.
