> Translated from Chinese.

# Android 17 HWUI: Two NVK graphics queues

## Result

- The binary NVK and vendor images have been constructed successfully; this task has not stopped, started or modified the running Waydroid.
- The real Android 17 bionic x86_64 / i686 independent public Vulkan probe reports `graphics_family=0 queueCount=2` and is submitted through two threads, GPU fill and CPU readback.
- The final combination is the original Rust RM backend/HAL/libdrm/nvrm/Codec2, probe measured.
- 19 bundle prebuilts in vendor. img are consistent with the new bundle by byte; image build_record properties equal to the new BUILD-RECORD.json SHA256.

| Item | Path/ Identity |
|---|---|
| Source submission (`a17-local`, not sent) | `eec39aa`: two separate NVK columns exposed to Android 17 HWUI |
| project submission | `c5aaf35`: Fixed Android 17 HWUI double queue NVK original package identity |
| Newly Full | `nvidia/build/native-multiqueue/` (includes payload, original gates, new BUILD-RECORD, SHA256SUMS.native) |
| New Bundle release | `v0.2.0-rc10-a17-multiqueue` |
| BUILD-RECORD SHA256 | `684a32a51133fe326904a67bc2a905e95cce52c0da5949dbd5bbeff0992c3565` |
| Vendor image | `src/out/target/product/waydroid_nvidia_x86_64/vendor.img` |
| Image size / SHA-256 | 898494464 bytes / `65f00c4df7d2d454ebc183b22c646ddadb27768885646e55e88b8f80ea1e44d4` |
| Original modified build log | `logs/nvk-multiqueue-native-build.log` |
| vendor Build Log | `logs/nvk-multiqueue-vendorimage.log`（`build completed successfully (01:36)`） |
| Mirror Read-only Checking Records | `nvidia/waydroid-nvidia/build/nvk-multiqueue-probe/image-check/result.json` |

## Why the queues must be independent

A17 `frameworks/base/libs/hwui/renderthread/VulkanManager.cpp:232-244` Requires two queues in the first rows family, `:441-442` obtains queue 0 and queue 1; `:543-544` binds RenderThread context queue 0, upload context queue 1.

The second is not a backup handle: `HardwareBitmapUploader.cpp:108-117` creates **GrallocUploadThread**; `:239-261` creates `kUploadThread` Ganesh context, uploads the pixmap to AhardwareBuffer and executes `submit(GrSyncCpu::kYes)`. Its `mVkLock` does not collusive the submission of RenderThread, and both threads can co-exist into the drive.

Reading native README, Mesa README, RM-ADAPTER, SYNCHRONIZATION, ASYNC-SUBMISSION, nvkmd_rm.c, rm-integration. patch, and pin Mesa 's queue-family/ queue creation code. `ddaf85e353442d9d7f192fdcf1823e652e3f2ee3` （26.2.5）。

### Existing per-VkQueue submission contexts

1. Mesa `nvk_device.c:370-374` Call each queue index `nvk_queue_create` 。
2. Mesa `nvk_queue.c:409-447` allocates new queue, `exec_ctx`, draw constant buffer, push street and initialize graphics/ compute state.
3. `nvkmd_rm.c:1238-1263` Each time a new C contact is allocated, and calls `nv_rm_context_create`; pending pushes, waits, last token are private.
4. Rust `src/mesa.rs:1357-1385` adds a new `Queue` to dynamic `Vec<Option<Queue>>` each time it is created, without a single graphics limit.
5. `src/gpu.rs:1350-1544` Every time an independent independent unit is created, GPFIFO, tail, TSG (0xa06c), context-share (0x9067), Channel, USERD, integration surface and retrieval slot. The `subcontext=0` for each TSG is an index in this TSG, not a single graphics channel for the entire device.
6. `Bridge.inner` mutex protects shared Rc graph, distributor, sync payload and scrack; cPUwait to run the confext ring and ring pressure in the lock is retryed at Cadapt without the mutex. Synchronize and recycle the contact id/token track.

So the minimum modification is only `native/mesa/nvk-rm-graphics-multiqueue.patch` to replace the graphics family `queue_count` with 2. `build.py` Add the patch to the NVK catch stack, `native_rust_profile.py` add it to the source hash snapshot; README indicates ownership and probe. Rust backend, map two VkQueue to the same ring, or add a worker.

## Build environment and original faithful rebuild

Use official `packaging/native/Containerfile` to repeat in rootless Podman; no toolchain or modified drive installed to host. Basic mirror `fe6972d4dc1f660c0c10f4c41b2de8986bab89e7e2955378f8beadb8ebcd7433`, Arch Archive snapshot `2026/10/15`. Local final build mirror `localhost/nvk-native-a17`, ID `ce24d8fb2965454c17907d0097c32fa59fe7ac76dbd4966ff16103e5d045e072`.

Tools: Rust 1.95.0 (59807616e), Cargo 1.95.0, Android x86_64 and i686 targets, Meson 1.12.1, Ninja 1.13.2, host GCC 16.2.1, LLVM/Clang 23.1.1, NDK r29 `29.0.14206865` API 33 (NDK Clang 21), bindgen 0.72.1, cbindgen 0.29.2, libdrm 2.4.134, Android static libelf 0.8.13, and the libclc and SPIR-V translator versions pinned by checksum in `host-build-deps.json`. The new record lists the full container package versions under `nvk_build_environment`.

Network: The Arch default network was timed, host network successfully; Rust official station TLS EOF, using rsproxy to get the same RustVersion pin. Keeps the completed system dependency layer, installs Rust and saves the container mirror. `hwcomposer/provision.sh ndk clones imagelibs` Provides a pinned AOSP headers and Android 13 link-time libs; double ABI libdrm is built using the original Makefile warehouse. Probe runs from the current ATV **Android17** `ref/system.img` to read only the true bic file. The host already has `dump.erofs` and does not need to add additional software packages.

Started successfully with host, Android x86_64, Android i686, without access to the double queue patch source code. rc10 BUILD-RECORD lists all native source hashes. Baseline is maintained in `nvidia/waydroid-nvidia/build/nvk-baseline/{host,android,android32}/`; the complete comparison is `comparison.json`, `sections.json`.

| ABI / File | Local Baseline SHA256 | rc10 SHA256 |
|---|---|---|
| x86_64 NVK | `e15bc94d85325849ec20d62781442e1e3e5452f8418552244fad024c12540c28` | `560d18fb2c6207fcb2b022663788bea46e5eaab06f05ff9083f9acb00b9ad2cb` |
| i686 NVK | `ba0e19d3061e93cca4f476bd0e05b9c755f9f6da764dcb11d2341ce69985c89f` | `c31ea568ace09ade5c87bf018ffaaaf18655690853372eba7e455ad1ed5bc09a` |
| x86_64 Rust RM | `8ec8824b776eed4fec5fdfa845629cdf6101af1eb81fcaf6b5f64f0cbfaff4b4` | `3ef545204f8f4ea9f9df9ae258ddf233600cdb2fab307d348b05e1a3d793eea3` |
| i686 Rust RM | `f33bcf628ba828be90d92fd70a31cb6cd0a668b0a65e44308717ed45c5ed6ca3` | `3ddde70d7f4c7abeab0f74474329377453c1883415d3a29792c3edf9af72cd60` |

Not the entire ELF by bytes: local prefix `/work` With author `/home/forsen/native-ci/waydroid-nvidia` Different. Pyelftools compares all SHF_ALLOC, non-NOBITS section: two Rust RM files are identical when all run; two NVKs `.text` 、 `.rodata` The code/ Constants section is the same and the differences are limited to dynamic string, link address/reposition, data pointer and build-id. `readelf -d` Confirm rc10 owns the author's absolute path RUNPATH, local co-description as `/work` Path, influences the length of the string table and the layout of the link. [INFERENCE] NVK layout differences explain this and do not claim to be semantic proof of full repositioning.

## Modify Version Products and Probe

| ABI | Final `libvulkan_nouveau.so` SHA256 |
|---|---|
| x86_64 | `fbc2cd2d3ea44f5b29bbcb36113ca3fd6ac3f8ddf0eb952e1c10f3752f3f4bb3` |
| i686 | `54cd8dccafcfbf5e85f814945542fa8002259b773341560880bb1d8ad2f01b0f` |

The original build product is `nvidia/waydroid-nvidia/build/nvk-{android,android32}/src/nouveau/vulkan/libvulkan_nouveau.so` and the actual deployment copy is `payload/vendor_extra/{lib64,lib}/` in the new bundle. HAL `hw/vulkan.nvidia.so` is the original rc10 wrapper, whose queue-family query is forwarded to NVK; no modification/rebuilding is required.

Eventually bundle replaces only the two NVKs, retaining the original Rust back bytes. `nv_rm.h` Unchanged, the baseline of Rust Runtime sections is more consistent; retaining the original bytes makes the original construction association of nvrm `nvrm_rust_sha256` Keep real. New record clearly distinguished. `base_release` to keep back `rust_builds` Local NVK `nvk_builds` , back metadata, and eventually backhead hash; there is no local re-alignment that is faked as a whole.

New probe `tools/native-vulkan-multiqueue.c` compiled using NDK r29/API33, selects NVIDIA/ Mesa NVK, print head graphics familyly, creating two different VkQueues. Each thread holds its own commmand pour/ buffer/fence; pthread Barrier releases two submiters simultaneously, then verifies the GPU fill by word. Each ABI 512 submissions, 524288 words.

Real output (two ABI identical):

```text
device=NVIDIA GeForce RTX 4060 Laptop GPU (NVK NV197) driver=NVK Mesa 26.2.5 (git-ddaf85e353)
graphics_family=0 queueCount=2
PASS: two concurrent graphics queues, 512 submissions, 524288 words checked
```

Evidence Directory `nvidia/waydroid-nvidia/build/nvk-multiqueue-probe/`:

- `logs/android-multiqueue.log`, `logs/android32-multiqueue.log`; exit are zero.
- `results.json`, `runtime-origin.json`; 32-bit uses user/ PID namespace runner of release date to avoid bionic restrictions on the host high PID.
- `runtime/{lib64,lib}` Read-only extraction copy of A17 system; not written to guest.

Original modified version double ABI construction `build.py --target android/--target android32 --rust-profile release -j 12`, offline. 32-bit reservation is aligned with 64-bit amics, unshielded; this probe does not address all upstream warnings or Vulkan conformance.

## Product, vendor and host date

Product `vendor/nvidia-prolapse/native-bundle.json` The fixed line root directory is relative to bundle path and record hash. `scripts/stage-product.sh` Read it, first checking record hash and payload hashes, and then copying payload to `src/vendor/nvidia-prolapse/prebuilts/native/payload` to generate `identity.mk`. `scripts/reinstall-vendor.sh` OTA packagings also read the same pin, avoiding error in the use of rc10 record. The root scripts do not belong to the project git; project company track pin itself.

Run:

```sh
scripts/stage-product.sh
scripts/build.sh lineage_nvidia_waydroid_x86_64-cp2a-userdebug vendorimage
```

`vendor_image.check_prebuilts` Read-only extracting and checking 19 prebuilt images: all consistent with the new bundle. Read Vendor build. prop confirms:

```text
ro.vendor.nvidia_prolapse.version=v0.2.0-rc10-a17-multiqueue
ro.vendor.nvidia_prolapse.build_record=684a32a51133fe326904a67bc2a905e95cce52c0da5949dbd5bbeff0992c3565
```

`release_gate.verify_bundle` Through, the new record accurately overwrites 68 payload/gate files. The installation gate also requires the full Vulkan/ GL/Codec2 cases on the target GPU/ kernel; this task performs only two queue special probe and read-only image/bundle checks, and no gate is installed.

### Accurate host installation step for the main agent (this task is not performed)

1. If you need to install the host tool, you will have to perform the host installer first. Its wrabper is currently fixed rc10 release. It will be written into the original native bundle; therefore it will have to be completed before the new bundle cutover below.
2. The main agent completes the Waydroid security stop, confirming the stapped status requested by the setup.
3. Synchronize new bundle to host from the root directory:

   ```sh
   sudo rsync -rlp --checksum --delete \
     nvidia/build/native-multiqueue/ \
     /usr/lib/waydroid-nvidia/native/release/
   sha256sum /usr/lib/waydroid-nvidia/native/release/BUILD-RECORD.json
   # For 684a32a5113fe326904a67bc2a905e95cce52c0da5949dbd5bbeff0992c3565
   ```

4. Pack and install matchVendor with project scripts modified, selected pin:

   ```sh
   scripts/reinstall-vendor.sh
   ```

   It calls `packaging/vendor-ota.py` to generate `out-ota/`, installs OTA zip/channel to `/usr/lib/waydroid-nvidia/vendor/`, and then runs `sudo env LC_ALL=C waydroid-nvidia-setup`. Setup verifies new bundle, zip/channel, image prebuilts and build_record to run full release gate on GPU/loaded core, updates installation records and codec XML after success.
5. Starts and sets/ validates `debug.hwui.renderer=skiavk` by the main agent to check HWUI/RenderThread/GrallocUplouadThread logs, images and NVIDIA Xid. Special probe does not replace this step.

Gate Based on: `release_gate.py:73-92` Verify bundle file collections and hashes; `vendor_image.py:151-162,240-259` Verify image bytes, record database and GPU date. `/usr/lib/waydroid/tools/helpers/nvidia_native.py:1620-1677` Check at startup for image identification, installation record, installed package record, image Hash, kernel version and codec XML. Unable to overwrite vendor. img or hand-modified build.prop bypass date; must match the host bundle, mirror and setup installation records.

## Remaining risks and limits

- The real `skiavk` launch of Android, hardware bitmap upload and visual images are installed by the main agent; this task does not claim to have completed Android UI acceptance.
- Independent TSG/channel does not amount to an independent physics graphics engine; the GPU can schedule time sheets and Vulkan does not guarantee that physics is executed simultaneously.
- Existing foreign sync-file, device-loss, recycling and GPU semaphore bindings remain unchanged; see `SYNCHRONIZATION.md`.
- Continues the original formulation development RUNPATH (new product `/work/...`; Android physical library search relies on vendor namespace/SONAME, probe explicitly uses bundle LD_LIBRY_PATH. No extra RUNPATH clean-up or rewrite extra running logic is added to this task.
- No host NVIDIA drivers, kernel packages, guide configurations were replaced; no Waydroid life cycle was restarted or operated.
