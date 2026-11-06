> Translated from Chinese.

> This is a historical upstream report. Packaging commands and file paths refer to the [upstream repository](https://github.com/cagedbird043/waydroid-a17-nvidia/tree/a17-20261031-2).

# Porting waydroid-nvidia (nvidia-prolapse) to Android 17

## Result

| Item | Status | Evidence |
|---|---|---|
| System image | WayDroid-ATV LineageOS 24.0 (Android 17, SDK 37) GAPPS version `20261017` (md5 `17ea7ba1…`), unchanged | `ro.build.version.release=17` GMS/GSF/Play store installed |
| Vendor image | Self-edited `lineage_nvidia_waydroid_x86_64-cp2a-userdebug`, `ro.vendor.nvidia_prolapse.version=v0.2.0-rc10-a17-multiqueue` | `src/out/target/product/waydroid_nvidia_x86_64/vendor.img` |
| native bundle | rc10 Rust RM/ HAL/ nvrm as it is, NVK to double graphic queue (`nvidia/build/native-multiqueue`, BUILD-RECORD sha256 `684a32a5…`) | `reports/nvk-multiqueue.md` |
| Release gate | PASS: 22 examples + media, kernel module 615.78.08 | `logs/nvidia-setup-6.log` |
| Start | `sys.boot_completed=1` Crash buffer 0 times abort | `logcat -b crash` |
| GLES | ANGLE → NVK → RTX 4060 Laptop | `ANGLE (NVIDIA, Vulkan 1.4.354 (NVIDIA GeForce RTX 4060 Laptop GPU (NVK NV197)), NVK-26.0.128.5), OpenGL ES 3.2` |
| HWUI | `skiavk`（`Pipeline=Skia (Vulkan)`） | `dumpsys gfxinfo` |
| gralloc | `minigbm_gbm_mesa`，`/dev/dri/renderD129`（NVIDIA） | `getprop ro.hardware.gralloc` |
| Hardware video decoding | H.264 / HEVC / VP9 / AV1 1080p60 decoded by `c2.nvprolapse.*` (NVDEC) with normal image | Just Player + logcat |
| Xid | Full 0 `NVRM: Xid` (including two rounds of glmark2 and HWUI benchmarks) | `dmesg` |
| binder | `/dev/binder`, `hwbinder`, `vndbinder` available | `service list` |
| KernelSU | Local signature manager 32708 displaying Working (LKM), no update hint; after Termux is authorized `su -c id` Got it. `uid=0(root)` Refusal after withdrawal of authorization | `reports/ksu-manager-local.png` |

## Repositories and changes

| Repository | Branch | Contents |
|---|---|---|
| `src/hardware/waydroid` | `nvidia-a17` | hwcomposer port 18 submissions and `%llx` Format Amendments (Form) `hwcomposer.md` ）； `c7c062f` Show-full-ui still without windows; `ef2e651` A17 Layer map to task by mission event; `5db77ae` Multi-window freeform card mode; `6e906c5` Android desktop window under multiple windows; `9edad77` Host input method direct ( `hostime/` 、 `hwcomposer/ime-bridge.*` ）； `f622087` Clipboard to ext-data-control; `4ffc464` The other package 's activity level (set search, share, access page) is brought to focus when entering the task and the card ' s entire window is restored to transparency; `7ceb257` Send the text before and after the cursor to the host ' s input method (long-selection accent characters, etc.); `742c344` Desk ID Reread WMshell 's own records to fix SystemUI 's repeated crash; `d061211` Card size and hand with your own mission, activity is not a guest, blacklist recognition, WMS component writing. |
| `src/external/minigbm` | `nvidia-a17` | gbm_mesa port 7 submissions; `cros_gralloc_handle.usage` returns to `int32_t` (`minigbm.md`) |
| `src/hardware/interfaces` | `nvidia-a17` | Composer 2.1/ 2.4 Reconnected amendments (`composer-hal.md`) |
| `src/external/wayland-protocols` | `nvidia-a17` | Protocol version up to 1.49; `06ffc32` Add ext-data-control-v1 |
| `src/device/waydroid/waydroid` | `local-build` | x86_64 Not edited by Mesa nouveau Vulkan; `edf992a` Preloading `WaydroidHostIme`; `e3248b0` Preloading `WaydroidFrameworkOverlay` |
| `src/vendor/waydroid/init` | `nvidia-a17` | `c75eb53` Identify nvidia-prolapse; `5a6d921` Video decoding to NVDEC |
| `nvidia/waydroid-nvidia` | `a17-local` | EROFS/ APEX/ VNDK support, KernelSU seccomp patch, double queue NVK (`eec39aa`), local installer (`db78568`, `fa99138`; installer does not rewrite existing directories and only refresh icon caches when icon changes occur (`d5c3d83`, `0d45957`, `035d267`); `1b5eaae` remove host side Python clipboard service |
| `nvidia/product` | (Major branch) | `libhwminijail`；native bundle pin（`c5aaf35`） |
| `ksu/KernelSU` | `local-manager` | Manager Source (b42ad459), local keystore signature |

`nvidia/work/` and in the context of the `hardware/waydroid` 、 `external/minigbm` Sync, `scripts/apply-nvidia.sh` From these clones. `vendor/waydroid/init` Two submissions only `src/` In the trees.

## Everyday commands

- Reassemble and reassemble: `scripts/build.sh lineage_nvidia_waydroid_x86_64-cp2a-userdebug vendorimage`, then `scripts/reinstall-vendor.sh`. The latter wraps up the vendor and calls `scripts/install-waydroid-nvidia.sh` to install the whole set of local `a17-local` source code (native binle from project pin, vendor from `out-ota/`, seccomp and locking changes) and finally runs `waydroid-nvidia-setup`.
- When you change hwcomposer only: `scripts/build.sh lineage_nvidia_waydroid_x86_64-cp2a-userdebug hwcomposer.waydroid` (approximately 1.5 minutes), `waydroid session stop` copy `src/out/target/product/waydroid_nvidia_x86_64/vendor/lib64/hw/hwcomposer.waydroid.so` to `/var/lib/waydroid/overlay/vendor/lib64/hw/` and start the session (approximately 20 seconds). The library in overlay takes precedence over the vendor image; before you install the new vendor image, delete it, otherwise use the old library.
- Just want to check the installation: `bash scripts/install-waydroid-nvidia.sh --destdir /tmp/stage` (no sudo is required).
- Baseline: `scripts/bench-hwui.sh LABEL`, summary `scripts/bench-summary.py LABEL...`.

## Android 17 issues and fixes

1. **`gralloc-mapper is missing` (composer and SurfaceFlinger abort).** ATV's C++ `waydroid-init` driver table has no NVIDIA entry and falls back to `gralloc=default`, which lacks a mapper. If the vendor image includes `vulkan.nvidia.so`, select `minigbm_gbm_mesa` and `vulkan.nvidia`, while preserving the host's `ro.hardware.egl` value.
2. **SurfaceFlinger reports `Failed to create a valid texture`.** ATV's Android 17 minigbm widened the handle's `usage` to `int64_t`, increasing the handle from 35 to 36 integers. The prebuilt HAL expects 35. Restore `int32_t`. The handle uses only the low bits of usage for software read and write masks.
3. **HWUI asserts `queueCount < kRequestedQueueCount`.** Android 17 HWUI creates two queues in the graphics queue family. RenderThread uses the first and the `HardwareBitmapUploader` upload thread uses the second. They submit concurrently. NVK originally reported one queue. The `nvk-rm-graphics-multiqueue.patch` patch exposes two. Each VkQueue already has an independent RM context, TSG, channel, and GPFIFO, so the Rust backend needed no change. The two-thread probe passed 512 submissions on both x86_64 and i686.
4. **KernelSU's `ksud` receives SIGSYS.** Waydroid's LXC seccomp policy killed all `reboot(2)` calls. KernelSU passes its driver file descriptor via `reboot(0xDEADBEEF, …)`. Use `reboot kill [0,3735928559,SCMP_CMP_NE]` to keep killing other reboot calls.
5. ** Video play failed (`c2.ffmpeg.*.decoder died`). ** ATV sets `c2.ffmpeg` video rank to 0, before the NVDEC service `c2.nvprolapse` (0x10); `c2.ffmpeg` DRM hwaccel calls `eventfd` at initialization on NVIDIA and is terminated by ffmpeg service seccomp. nvidia-prolapse sets `c2.ffmpeg` video rank to 32 and closes its DRM hwaccel, which is softened after NVDEC.
6. Build environment. The Rust part of Mesa nouveau could not find i686 rustc in the offline container and removed nouveau (NVIDIA with its own NVK); the `ld.lld` symbol link was filled in the container; the hwcomposer `-Wformat` error.
7. **Multi-window mode (`persist.waydroid.multi_windows=true`).** Android 17 puts the `TID:` prefix on surfaces without buffers. App content is on `VRI-<pkg>/<activity>` child layers, which hwcomposer maps to tasks using WMS events. The system image has stale task-service transaction IDs (`setFocusedTask` became `removeTask`, so clicking a window closed its app). Hwcomposer now calls `cmd activity` and `cmd window` directly. The Android display stays fixed while tasks run in the WMShell desk as freeform windows. KWin gives each task a top-level window and handles decorations, movement, and resizing. Android decorations are cropped, task bounds follow the window size, and switching windows needs no display reconnect. Rounded desktop corners force CLIENT composition and make app windows transparent, so freeform mode disables them.

## KernelSU

- kernel module: `kernelsu-dkms 3.3.1+28+gb42ad459-2`. `~/.cache/yay/kernelsu-dkms/PKGBUILD` pkgrel 2 for `KSU_EXPECTED_SIZE=0x02ec`, `KSU_EXPECTED_HASH=d77ee93d…` to write to MAKEs in dkms. The kernel therefore recognizes the local signature manager and the official manager is no longer recognized. Upgrades the Kernelsu-dkms to keep these two variables (extract values in `ksu/out/expected.txt`).
- Manager: `ksu/out/KernelSU_v3.3.1-28-gb42ad459_32708-local.apk`, keystore in `ksu/keystore/` (access 600, password in same directory README). For construction instructions see `ksu-manager-build.md`.
- Loading: `/etc/systemd/system/kernelsu-load.service` (source file) `host/kernelsu-load.service` Here. `waydroid-container` Run Before `load-kernelsu` , when the module is loaded, skips. The container is automatically executed init on startup `ksud post-fs-data` / `services` / `boot-completed` 。

Empty data will be thrown away `/data/adb/ksud` and the manager: `lib/x86_64/libksud.so` removed from the manager APK as `data/adb/ksud` (root: root 755), running in the container `/data/adb/ksud install`, reloading the local manager in `ksu/out/`, and reopening the session (see `kernelsu/README.md` for the command). `persist.waydroid.multi_windows` There is also a Data in the database and needs to be re-established `waydroid prop set`.

## Multiwindows

Set `waydroid prop set persist.waydroid.multi_windows true`, restart the session, and use `waydroid app launch <package-name>` to open each app in its own KDE window.

Opens the full Android desktop from the "Waydroid" (`waydroid show-full-ui`) starting menu and places it in a normal window with the KDE titlebar to drag, zoom in, maximize, and Android displays a change in window size. All applications are on the desktop when the desktop is open, using Android 's own window titlebar; when the application is opened from the host, it is also opened separately and the desktop is mentioned in front. Closes the desktop will not end the application, each returns to the original KDE window, and the size is restored to the value before opening the desktop. The two states do not exist simultaneously: all applications share an Android screen, and separate windows hold screen positions in the desktop, although they are not visible, will intercept the click.

Actual measurements have been made on the desktop (build-22): calculators and clocks are in the right place; keyboard input; drag title bar moves; KDE zooms to a new size; long copying/ paste floating toolbars are displayed properly and do not allow windows to jump; clipboard double-trip (Android copy `wl-paste`, `wl-copy` →  Android paste); windows are removed with Android tasks after the point closes the button; dmesg does not have Xid.

### Card Scale

When dragging the KDE window border, hwcomposer gives each new dimension `cmd activity task resize` The latest request for the same task is left only. A17 When the shell transposition is on, the WM first intercepts a copy of the task at each time the size is changed by WMShell. `DefaultTransitionHandler` Animation of about 400 ms of size change ( `port_window_size_animation` The next size change has to be behind it, so the card is clearly behind the drag. `WaydroidFrameworkOverlay` （ `hardware/waydroid/overlay` I'm going to have to go. `config_disableTransitionAnimation` Set True: `WindowContainer.canStartChangeTransition()` So, for false, no more snapshots and no animations. All Wydroid windows are animated by KWin, and Android's own transition animations are not visible on the mainframe. The measurements take from hwcomposer to card sizes of about 40 ms (about 400 ms plus 3 more stabilization periods).

Two problems that could cause the card to be disassembly:
- WMShell's desk background `DesktopWallpaperActivity` does not draw `Task=` layers where the old logic counts it as a "guest" for the focus task, the full screen height is added to the card content area, the card is held up to 1199 dp and runs out of the screen. The activity with its own task is now its own task.
- The activity blacklist failed to recognize the `pkg/.Cls` notation used in WMS events. The desk background could therefore create an empty 1×29 window.

Clipboard is run by wwcomposer (Android) `ClipboardService` Call HIDL only `IWaydroidClipboard` , never call the side of Python `waydroidclipboard` , the service has been deleted, see `waydroid/0003-drop-python-clipboard-service.patch` . hwcomposer binds to the control connection `ext_data_control_manager_v1` (Clipboard manager protocol):
- The host will notify hwcomposer of the need to focus the Waydroid window every time a copy is made; hwcomposer reads the text on a separate line, through `@waydroid-hostime` Out. `WaydroidHostIme` ♪ By it ♪ `setPrimaryClip` . This must be done: leave the text only `ClipboardService` When passive pulls, the frame does not send a Clipboard Change Notification, and WebView (browser, etc.) pastes the old content.
- The wwcomposer directly sets the host clipboard at the time of copying and does not need to input material, remains after the focus has been removed; Android returns precisely when the host text is not rewritten and the host retains the original constituency.
- The mixer returns `wl_data_device` when it does not have an ext-data-control (following keyboard focus).

Actual (KWin, card mode settings search box and browser WebView input box, desktop window): Host copy  →  to Android paste  →  Add character  →  Full copy  →  Toggle Host `wl-paste` , set 5/5, WebView 5/5, desktop window 3/3 (Chinese, emoji, multi-line); dmesg does not have Xid. Debug: `waydroid prop set persist.waydroid.clipboard_debug true` Restart Session, logcat `hwcomposer` Medium `clipboard:` All right.

## Host Input Method

The host 's input method (the one selected by the " Virtual Keyboard" in the KDE setting, which is Fcitx 5; ibus and so forth) can be typed directly in Android applications, with cards and desktop windows available. Press Ctrl+Space to switch in the Android input box in Chinese and English, as applied by the host, and the selection box is next to the cursor of the Android input box.

Achieved in two parts:
- hwcomposeer binds `zwp_text_input_v3` to the Wayland control connection and gives the cursor position (converted to the coordinates of the window) to the host when the Android input box gets focus; the host input method does not eat the key as it is `wl_keyboard`.
- The vendor application `WaydroidHostIme` (`id.waydro.hostime`, `/vendor/app`) is an interface-free Android input method that puts top screens, pre-edits, deletes into the input box, and reports the cursor position.
- The two are abstract unix locket `@waydroid-hostime` where hwcomposer only accepts the uid connection to the package. The protocol is written in `hwcomposer/ime-bridge.h`.
- Vendor init(`/vendor/etc/init/waydroid-hostime.rc`) runs as a shell `/vendor/bin/waydroid-hostime-enable` to enable and set the default input method; the user does not change the default if it has selected an input method other than the original keyboard. The shell is used because `cmd input_method ime` of A17 only accepts shell/root, `cmd settings put` triggers the NPE under system uid.

It has been measured that: double spells are entered on the Chinese screen, numerical choice, decoupling, cut back to English, Ctrl+A/C, and the selection boxes are moved with the cursor; the desktop window is also normal; the hwcomposer is automatically enabled and attached to it after the start-up. dmesg does not have Xid. Whether the pre-editor is embedded in the input box is determined by host input methods, and the current fcitx5 configuration `PreeditEnabledByDefault=False` is pre-edited to appear in the selection box, as is KWrite.

## Sound

ATV audio HAL is AOSP default AIDL HAL with a PulseAudio output (`hardware/interfaces/audio/aidl/default/pulse`), made by the host of the container socket `/run/xdg/pulse/native`. Two questions (`device/waydroid/waydroid` `049cbe5`):
- `primary_audio_policy_configuration.xml` Declares that `mmap_no_irq_out`/ `mmap_no_irq_in`, HAL has given the MMAP stream to Cuttlefish `StreamOutMmapStub`, and the sound is discarded. Chrome 's web audio walk AAudio, will select MMAP, and then the web game is silent. When these two words are removed, AAudio returns to the normal path (log `got Legacy`, via AudioFlinger to `StreamPulse`. True MMAP saves little delay here: both buffers on the side of the mainframe PulseAudio/PipeWire have to pass.
- The system image set `ro.config.media_vol_default=16`. AudioService rejected values above step 15 and fell back to one-third volume (step 5, about −32 dB), making playback barely audible. Set the vendor property to 15, since vendor `ro.` properties override system ones. Volume is controlled on the host.

On-the-spot: The WebGL game in Chrome has a sound; the saved volume is deleted and restarted, and the loudspeaker media is defaulted on 15/15.

## File Sharing

The host's `~/Downloads` appears in Android as `Download/Host`. The host Waydroid patch `waydroid/0004-host-shared-folders.patch` implements this. In `waydroid.cfg`, `shared_folders` takes one `host-directory:storage-path` entry per line.
- `/data/media` of Android only reads and writes by the FUSE process behind the MediaProvider (`/sdcard`, host uid 10120), so the uid/gid image of the host user uid/gid on the side of the Android is dropped onto the host to the current user. uid reads from `packages.list` and does not write death.
- vold Starts using the `/data/media` non-reciprocity bind to FUSE lower level path `/mnt/pass_through/0/emulated`, and the submount on board will not be carried in before then (Android side-writing will drop into the original directory under the mount point). So this path appears in the container 's init schedule before it is hung up and distributed into Android; unloading when the container is stopped.
- The mount point is placed under the Waydroid data directory of the host, which is owned by ordinary users, and the root uses fd (`open_tree`+`move_mount`) without the path when setting the directory and mount it.
- Storage path to be placed below the standard directory: MediaProvider only allows the application of a file in a top-level directory that accepts this type ( `Download` Accept all types. `Host` The directory can build txt but not png.

Verified that UID 2000 could create PNGs, text files, and directories via FUSE in `Download/Host` and read host files. Files appeared on the host with ownership 1000:1000. Host-created files appeared immediately in Android, and all mounts were removed after `waydroid session stop`.

The Android media library was not notified, so the container manager bugged the shared directory with inoty (no sign link, with a maximum of 4096 subdirectories shared each) and changed the silent 1.5 seconds (up to 10 seconds) of `scan_file` to hand over to MediaProvider in batches: cleaning a non-existent path will remove its records and sweep the directory to cover the entire tree; a batch of more than 8 paths will be followed up to the top directory. Actual: new images, subdirection of images, movement, removal of files, one copy of 30, deletion of the entire directory, and the media library will be identical to the host machine in 6 seconds.

## GApps

System uses the ATV version of GAPPS, vodor, without change. The device fingerprint is Pixel Tablet (`google/tangorpro/tangorpro:17/CP2A.260705.006`). Play stores need to register the GSF ID (`/data/data/com.google.android.gms/databases/gservices.db` `main` table `android_id` to https://www.google.com/android/uncertified. The replacement has been verified: ANGLE/NVK renderings, HostIme autostarting, KernelSU opening process, desktop window, dmesg without Xid. Waydroid has no access to Play Integrity's integrity check and mandatory application (bank etc.) of the check is not available.

## Performance: skiavk and skiagl

Run each configuration three times with the same vendor image and session conditions. For scrolling, swipe quickly up and down 15 times in the Settings app list and analyze the results frame by frame with framestats (10,800 frames per configuration). For cold starts, use the median of three runs.

| Indicators | skiavk | skiagl |
|---|---|---|
| The whole frame takes time means / p50 / p90 / p99 ms | 1.55 / 1.42 / 2.10 / 3.05 | 1.72 / 1.59 / 2.27 / 3.14 |
| RenderThread mean / p50 / p90 / p99 ms | 1.28 / 1.16 / 1.69 / 2.70 | 1.45 / 1.36 / 1.88 / 2.79 |
| GPU means / p50 / p90 / p99 ms after swap | 0.61 / 0.51 / 0.98 / 1.96 | 0.71 / 0.63 / 1.01 / 1.97 |
| Carton Frame. | 0.01% | 0.01% |
| Cold Start Calculator ms | 167 | 184 |
| Cold StartDeskClock ms | 156 | 184 |
| Cold Start Jelly Browser ms | 288 | 219 |
| Cold Start KernelSU Manager ms | 591 | 611 |
| Just Player ms | 161 | 167 |
| Grammark2 2023.01 score | 6499 | 6605 |

- Interface Rendering: The skiavk whole frame and RenderThread are close to 10%, both well below 16.7 ms, no perceptible Carton.
- The glmark2 itself takes the GLES (ANGLE  →  NVK), without passing by HWUI, with a 1.6% difference in scores, which is normal; it measures the GLES path and does not reflect the difference between the two HWUI modes.
- Cold start: skiavk is a little fast, except for Jelly; Jelly, in turn, is fast 70 ms, possibly related to WebView’s initialization, not deeply studied.
- Keep `skiavk` (project default, `waydroid-nvidia-setup` will write this value).

## Known limits

- The 64-bit build of glmark2 crashes because its own `Log::info` reuses a consumed `va_list`. This is a glmark2 bug. Testing used the 32-bit build instead (`pm install --abi x86`).
- SetupWizard is still on the first screen: ATV skips a bluetooth pair of patches and the source code does not clash, and the first opening is done manually.
- The installation source certificate was not verified: there were no cosigns and signature bags locally and the installers only performed SHA256 and BUILD-RECORD verifications.
