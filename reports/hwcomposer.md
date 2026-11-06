> Translated from Chinese.

# hwcomposer NVIDIA patch port report

## Result

- Repository: `nvidia/work/hardware_waydroid`, ATV `lineage-23.0` baseline `3af187c`, local branch `nvidia-a17`.
- Final commit: `a309b1c`. Of the 18 patches, 17 were imported individually in order. Patch 0009 was skipped because ATV already implements the same behavior. One additional commit adapted connection and resource cleanup lifecycles.
- Imports the original author of the reservation and the original message; there is a suitable submission of additional instructions in Chinese. No pushout or synchronisation `src/` is performed.
- Old blobs listed in patches 0014–0016, 0018 cannot be reconstructed by `git am -3`; keep the am session, match the applicable block and original patch content and then execute `git am --continue`.

## Patch application results

| Patches | Outcome / Submission | Processing |
|---|---|---|
| 0001 baseline | Resolved, `a410dba` | Imports NVIDIA format/modifier access, opacity RGB import, server end decoration, client-end target drawing fixes and clipboard fixes; the object and input serial numbers are moved to `wl_conn`. Keep ATV tags, job close/screams, geometric ownership and recovery after the connection is down; use the ATV single configuration reze path to not include the fixed physical resolution mode ladder of A13. |
| 0002 formats mutex | Resolved, `16aaf5f` | Each `wl_conn` holds formatting, emulators and cross-locks independently; the advertising echoes the data connected to the imported access reading and writing. |
| 0003 NVIDIA EGL LINEAR | Resolved, `2eb7616` | LINEAR is rejected only in the format where the connection record exists. |
| 0004 wl_buffer cache | Resolved, `8b80a68` | Retains ATV `shared_ptr` and has a buffer job;ctl cache cleans up with an unused policy of 8 frames, adding dma-buf inode identity, and does not empty as geometry changes/thermal plugs. |
| 0005 no abort | Resolved, `29cd2e6` | Frame error returned failed; the detection of the shell protocol was missing and moved to `wl_conn_open`. The break wires of the ATV are retained. |
| 0006 named disconnect | Resolved, `ab097f7` | Ported protocol object and error-code logging and `waydroid.hwc.wayland_lost`. Preserved ATV's control reconnection and per-task connection cleanup. One task's disconnect no longer kills the others with process exit code 75. |
| 0007 SIGPIPE | Resolved, `a043b2f` | Ignore SIGPIPE while retaining the ATV startup cleans out old window properties. |
| 0008 cursor importability | Resolved, `e35458e` | ctl standard access check on connection and wl_shm retreat; ATV is reserved for acquire-fence processing. |
| 0009 HIDL threadpool | Discarded: Equivalent patch | ATV `bb49e33` is no longer shrinking the cascading pool of the composer service configuration; it is maintained to achieve it and to avoid reconfiguring the activated cascading. |
| 0010 SHM fallback | Resolved, `87cacbd` | Use the wl_shm of the current ctl for layers that cannot be imported directly, and continue using the ATV share ownership. |
| 0011 acquire timeout | Resolved, `2623322` | Keeps `shared_ptr` arguments; 1 second forfence completes geometry/refaction after it fails. At 0014, you will wait before the GPU copy and attach. |
| 0012 monotonic timestamps | Resolved, `5522f39` | Presentation clock saves by connection;ctl feedback only enters vsync when CLOCK_MONOTONIC. Keeps ATV's task-streams mode awakes logic. |
| 0013 viewport clamp | Clean application, `ecd4984` | Crop rectangles are limited to buffers that are rotated. |
| 0014 cross-GPU PRIME | Resolved, `f079758` | dmabuf v4 feedsback, repent_path, copy pool to `wl_conn`; FBT reserves shared caches and fence time series; releases copy source, copy pool and feedback when connecting to reconstruction/destruction. |
| 0015 YUV / planes | Resolved, `cc680d2` | Keep wl_conn API, transmits all plane; YUV to SurfaceFlinger, whose format is not supported by SHM is clearly failed; cross square arrays are pre-constructed to check the DRV_MAX_PLANES range. |
| 0016 hotplug outside present | Resolved, `a3a579c` | Removes `hwc_set` master display hotplug and needHotplug; reserves ATV input pipe updates and frame requests, and adds poison to prevent present/ Wayland files from sending hotplug directly. |
| 0017 Soong prime-copy | Clean application, `741cd44` | Android.bp is included in the prime-copy.cpp, adding Vulkan headsers, and retaining the missing field initialization warning settings. |
| 0018 safe resize | Resolved, `50f55a6` | Reuse the ATV window geometric ownership with 250ms setle; move resize worker to an independent display-resize.cpp. Sends the main link from this thread only `ro.vendor.composer.safe_primary_reconnect=true` without a cell lock calling HAL. Keep a single config, the physical size is protected by modes_mutex; does not introduce a second set of staircases/lines. Android. bp compiles a new file simultaneously. |

## Additional adaptation for ATV tasks

ATV's `post_task_buffer` used fixed android_wlegl. NVIDIA/ KWin's dmabuf graphic path cannot rely on this protocol alone, so:

- Keep the ATV path when the current connection supports android_wlegl.
- Otherwise, use the current task `wl_conn` to import dmabuf: directly with GPU, and cross GPU to copy with LINEAR stored in the PRIME system.
- Keeps slot 's innode/ metadata weighting judgement, case waits, initial pre-configure storage, the latest frame and the old slot release policy when deactivated.
- `wl_buffer.release` of dmabuf uses life-cycle stable connections as userdata, then click on the connection and wl_buffer to find slot; avoids echoing references that have been replaced buffer.
- Copy pools are recovered with each connection; the main connection is reconnected without discarding other tasks.
- The above-mentioned release echo stability, reconnection format combination locking and compilation clean-up are completed in Chinese submission `a309b1c`.

## Verification evidence

- `git diff --check 3af187c`: Through, no output.
- `git status --short --branch`: Only `## nvidia-a17`, work tree clean.
- hcompposer conflict tag search: no match; `.rej`/ `.orig` search: no file.
- The relevant codes have been read and new statements/definitions/calls have been added to PRIME, resize, task-stream release, displayable_buffer, set_crop; Android.bp lists prime-copy.cpp, display-resize.cpp.
- Protocol dependency: PortComposer Hal has confirmed that the accompanying wayland-protocols branch updates the xdg-decoration and dmabuf feedback interfaces with `libwayland_extension_client_protocols` export head; this slick does not add creation rules.
- Unconstructed, unrun project test, and unstarted Waydroid. Static self-censorship is not equivalent to Android 17 compilation or running validation.

## Required runtime validation

1. Direct communication with GPU: full UI under NVIDIA/KWin, single windows, traditional multiple windows and task streams have images; confirm ANGLE/NVK, Block-linear moditier, `waydroid.hwc.present_path=direct`; cursor/transparency/design/clipboard is normal.
2. Add a task-stream path: at least two applications are repeated/closed/toggled using the taskstreams and traditional multi-windows, respectively; each connection window, Focus, to activate the snapshot and restore, first contact, slot releases without continuous EBUSY, black card or fd growth.
3. Trans GPU: Validate the PRISE path of FBT and task-stream under iGPU compositor, check `cross-gpu-copy`, LINEAR pitch stored in the system, buffer pool release, continuous animation and fast window switch/resize; including cases where the temporary frame is replaced by a follow-on frame. Confirms that failure copying will not be accompanied by the original NVIDIA visible buffer.
4. Connection failure isolation: reboot/ disconnect copositor or close a single tabk mainframe link to check for name error properties; ctl reconnectable, stand alone/reopen, other tasks are not killed, old wl_buffer/ copy pool agent is reused.
5. Security resize: Use the modified composer HAL and test the safe_primary_recontect properties separately. Drag, maximize, scale and fixed size on startup changes only after setle, do not reset from present, do not lock/ collapse; do not display a major link at close. Special check ATV geometric ownership does not resize single windows/multi-task, and during drag time the viewport displays the touch coordinates.
6. Video & Format: The YUV sublayer, such as Chrome/ExoPlayer, is synthesized by SurfaceFlinger, the colour domain/range is correct, there is no Wayland invalid_wl_buffer; confirming multi-plane parameters are complete and SHM does not support formatting to fail without killing connections.
7. Cache & Synchronization: Continuous geometry changes, reassigned size buffers, deactivated applications, decease aging normal; 1 s acquire overtime, cursor acquire Fence, CLCS_MONOTONIC and non-single representation clock do not cause freezing/continuing fd leakage.
