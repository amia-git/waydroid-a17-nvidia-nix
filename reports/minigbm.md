> Translated from Chinese.

# Minigbm: Android 17 NVIDIA patch transplant

Target: `nvidia/work/minigbm`, ATV `lineage-24.0` baseline `5f5797c`, local branch `nvidia-a17`; final submission `de6759b`. Unmodified synchronised `src/`, not pushed.

## Patch application results

|Patches|Result|Presentation and suitability|
|---|---|---|
|0001 CPU usage does not force LINEAR on GPU render targets|Conflict resolution|`1d44e03`: Reuse `unmask64` ATV consumption markers to keep the parameter declaration sequence, scanout/cursor, camera and RPI4/VAAPI alignment; CPU+ Rendering to keep nonlinear layouts and accept FRONT_RENDERING.|
|0002 pass the lock's access flags to the wrapper|Conflict resolution|`b46cadf`: Keeps the ATV demapping invalid status check to return to EINVAL, and then calls the extension with the READ/WRITE logo; retains the double lock mark extension and the old wrapper retreat.|
|0003 FP16 and 1010102 render targets from the wrapper|Conflict resolved|`3219d85`: ATV replaced the static format-combination table with `supported_formats` and still probes with `gbm_mesa_bo_create2`. Require the wrapper to allocate FP16 and 1010102 directly and reject an R8 fallback.|
|0004 P010 and a GPU-writable NV12/P010 layout for decoder output|Conflict resolution|`5d6cc2b`: P010 Access Dynamic Detection; Fit for New `drv_bo_from_format(..., stride_align, ...)` Signs. NVIDIA wrapper 's layout extension provides 256 bytes pitch, even height and plane position/volume; no export of this optional extended wrapper to keep ATV layouts and maintain other GPU/RPI4 paths.|
|0005 import into the wrapper on the first CPU map|Conflict resolution|`c34f6de`: ATV has first-time Map import and 4096 width R8 carrier, repeats the existing function and removes the SW 'smap/unmap limit that assigns usage; retains no plane parameter interface and adds map initialization failed to check.|
|0006 YV12 for hardware decoders, carrier sized to the whole YV12 layout|Discard (target covered)|ATV Dynamic Detection has accepted YVU420_ANDROID+ hard-codification markers; its carrier uses `4096 × ceil(total_size/4096)` to accommodate the full YV12 and no longer uses semi-wide restorations repaired by patches. Restoring the old static assembly table/replacing destroys the ATV. Use `git am --skip`, without independent submission.|
|0007 CPU-cached memory for buffers the CPU reads often|Conflict resolution|`3e6f2b4`: Read the original `use_flags_copy` to determine CPU_RED_OFTEN, to prevent ATV sign consumption from rendering the cache request ineffective; to keep test_only and failed scanout and to use the extension portal when retrying.|

Also submitted locally `de6759b` (in Chinese): Extension queries are used only for dynamic wapper, retaining the ATV embedded grinder compile path; formatted byte steps are also used for no layout extension to prevent P010 from being distributed half-wide.

The six original patches that have been imported are imported through `git am -3` and the author, the original message, is retained. The message text adds an appropriate description in Chinese.

## Static checks

- `git diff --check 5f5797c..HEAD` through; `git status --short --branch` Only output `## nvidia-a17`, working trees clean.
- There is no match for a fully cloned conflict tag scan.
- The statement after the removal of the note/blank from the four slipper ABI header files is identical to the pre-recorded source: Foundation `alloc_args/gbm_ops`, Map Flags, Layout, Alloc Flags. No changes have been made to the pre-record library or its header.
- Warpper has been identified to export four corresponding `get_gbm_*` symbols; the amount/map sign, format layout function and signature exist in the result source code.
- `gbm_mesa_driver/Android.bp` Internals/backend has been compiled into `libminigbm_gralloc_gbm_mesa`, alloctor/mapper@4.0 and continues to refer to it; the new content is only for headlines, no new `.cpp/.c` and no changes to the list of source files are required. `Android.mk` The normal Messa wrapper is still constructed; NVIDIA products are to be replaced by pre-compiled wrapper by the specified product layer.
- No build or project test is running; the complete Android tree is not available.

## Runtime validation

1. A17 alloctor/mapper@4.0 Load pre-compiler and three version extensions in 32/64 bits to distribute, cross-process import and release normal.
2. The CPU+GPU rendering (clip, screen recording) maintains the block-linear, READ/WRITE/ repeat lock copy in the right direction; the CPU-only buffer remains linear.
3. Verify that pitches for FP16 and 1010102 windows, wide color, and odd or unaligned widths match Android's plane layout.
4. 256 bytes pitch for NV12/P010, flat faceup/volume is consistent with NVDEC, NVK, ANGLE and host Wayland; 10-bit video and ByteBuffer without Surface decoding is normal.
5. Verify full, in-bounds output capacity for YV12 at 1920×816, 1920×1080, and wider resolutions. The first CPU lock should map decoder output even when it was allocated without software usage flags.
6. The CPU_RED_OFTEN decoding output without the original scanout does enter the cache memory, and the performance and synchronization is correct; the scanout distribution failed to try again without changing the NVIDIA intent.
7. Non-NVIDIA normal wrapper, RPI4 camera/ hardwired and ATV VAAPI paths do not revert on the reserved branch; the actual A17 Soong compilation still needs full tree validation.
