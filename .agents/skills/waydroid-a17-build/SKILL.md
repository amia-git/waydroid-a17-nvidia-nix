---
name: waydroid-a17-build
description: Build this project's Waydroid Android 17 NVIDIA vendor image and its pieces — single vendor modules (hwcomposer, gralloc, Codec2 service), the Rust RM backend / NVK / nvrm native stack, the native bundle and its pin, the full two-pass vendorimage — and keep publish/patches in sync with the source repositories. Use for any compile, rebuild, bundle, stage-product, Soong, or patch-export task in the upstream workspace.
---

> Translated from Chinese.

# Build

## Workspace

This repository is a subdirectories of the `~/Projects/waydroid-a17` workspace. The source code and the product are in the workspace.
`$WAYDROID_A17_WS`, default to take the next level of this repository.

| Workspace Path | What is it? | The match in this repository. |
|---|---|---|
| `src/` | LineageOS 24.0 + WayDroid-ATV Tree (repo) | `patches/<repository>/` |
| `src/hardware/waydroid` Wait | Branch `nvidia-a17` (device) The tree is `local-build` ） | `patches/hardware_waydroid/` … |
| `nvidia/waydroid-nvidia` | Branch `a17-local`: Rust RM, NVK, nvrm, Codec2 Media Source, Waydroid Host Patch | `patches/waydroid-nvidia/` |
| `nvidia/product` | `vendor/nvidia-prolapse` Project layer (git, main) | `nvidia-product/` (rsync mirror) |
| `nvidia/build/native-*` | native bundle（BUILD-RECORD.json + payload） | Release Assets |
| `scripts/` | Build.sh, stage-product.sh, etc. | `scripts/` (Same copy, running from the workspace) |

For baselines and quantities of patches, see [references/patch-bases.md](references/patch-bases.md).

## Single module (quick succession)

```bash
cd "$WS" && scripts/stage-product.sh      # After changing nvidia/product or media source
scripts/build.sh lineage_nvidia_waydroid_x86_64-cp2a-userdebug MODULE   # Like hwcomposer.waydroid
```

Product in `src/out/target/product/waydroid_nvidia_x86_64/vendor/`, put in `/var/lib/waydroid/overlay/vendor/` same name path,
Reboot the session (`waydroid-a17-test` skill). Overlay has priority over the vendor image and must be emptied before release.

Codec2 service module name `android.hardware.media.c2@1.2-service-nvprolapse`, source code from stage-product.sh
`nvidia/waydroid-nvidia/nvidia-prolapse/media/{core,c2}` Put in `src/vendor/nvidia-prolapse/media-src/`.
Host 's single measure: `make -C nvidia/waydroid-nvidia/nvidia-prolapse/media test`; true GPU: `make realtest-all`, `make realenc`.

## Native Lodge (after remodeling the dryer-source/)

Submit it in `nvidia/waydroid-nvidia`, then:

```bash
S=.agents/skills/waydroid-a17-build/scripts      # Run in this repository root directory
$S/rebuild-native.sh            # Rust RM  →  NVK nvrm (32/64 bit)  →  nvc2-xmlgen, approximately 2 minutes
$S/rebuild-native.sh --rust-only   # Rust library only, tested, not distributed
```

`nvc2-xmlgen` is a `xmlgen-cli` non-default feed bin with RM C ABI only being used dynamically.
R.M. First compiled and then used Make's Cargo adaption target (increment judged by Cargo each):

```bash
make -C "$WS/nvidia/waydroid-nvidia/nvidia-prolapse/media" xmlgen \
  RUST_PROFILE=release CARGO_TARGET_DIR="$WS/nvidia/waydroid-nvidia/build/nv-rm-rust" \
  NV_C2_RM_LIB_DIR="$WS/nvidia/waydroid-nvidia/build/nv-rm-rust/release"
# bionic: same target directory, with Android RM selected and NDK C linker displayed (not clang++)
make -C "$WS/nvidia/waydroid-nvidia/nvidia-prolapse/media" xmlgen-android \
  RUST_PROFILE=release CARGO_TARGET_DIR="$WS/nvidia/waydroid-nvidia/build/nv-rm-rust" \
  NV_C2_RM_LIB_DIR="$WS/nvidia/waydroid-nvidia/build/nv-rm-rust/x86_64-linux-android/release" \
  RUST_LINKER="$WS/nvidia/waydroid-nvidia/build/hwcomposer-work/ndk/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android33-clang"
```

Both targets check ELF64, RM dynamic dependence and caps/XML import; Android product also requires linker64 to ban GNU libc and developer RUNPATH.

nvrm records its link to Rust Quharshi, which is banned from the `libnv_bionic_native.so` comparison with Payload; only Rust library is not recreated nvrm,
`waydroid-nvidia-setup` Reporter `nvrm (x86_64) was linked against libnv_bionic_native.so …`.

## Full Vendor Mirror (two times)

Codec2 service in the mirror is required to match the bundle by bytes, and the service is to be compiled against the bundle, so:

```bash
.agents/skills/waydroid-a17-build/scripts/build-vendor.sh --base nvidia/build/PREVIOUS_BUNDLE --out nvidia/build/NEW_BUNDLE \
    --release v0.2.0-rc11-a17-SUFFIX --note "English summary of this release"
```

In turn: Generate bundle (retention of old service)  →  stage  →  with new service regenerate bundle and update the nails
`nvidia/product/vendor/nvidia-prolapse/native-bundle.json`  →  stage →  `vendorimage`  →  bytes check.
About 5 minutes (cache heat). Separately generated bundle: `make-bundle.py` of the same directory. After completion, submit a nail selection in `nvidia/product`.

## Synchronize to this repository

- product：`rsync -a --delete --exclude=.git "$WS/nvidia/product/" nvidia-product/`
- Patch: In Source Repository `git format-patch -q --start-number <N+1> -o patches/<repository>/ <last-exported-commit>..HEAD`,
  . Updates the quantities in references/watch-bases.md.

## Can't do it.

- Rewrite `nvidia/waydroid-nvidia` Medium `eec39aa` And before it was submitted (BUILD-RECORD remembers it, `install.sh --source` Q: What do you want from me?
- To "repair" a product other than `src/out`; build failed to read `/tmp/c2svc-build.log`, `/tmp/vendorimage-build.log`.
- Complete Vendor before completing a single module: Soong reporting errors is more quickly exposed on a single module.
