> Translated from Chinese.

# TODO

See `reports/porting.md` for status, test results, and porting notes. The build, test, and release workflows are in `.agents/skills/`.

## Status (2026-10-28)

- System image: WayDroid-ATV LineageOS 24.0 GAPPS `20261017`. The Play Store is certified.
- Vendor image: locally built nvidia-prolapse. ANGLE uses NVK, HWUI uses skiavk, and NVDEC and NVENC provide hardware decoding and encoding. H.264, HEVC, and AV1 encoding were tested with Chrome WebCodecs and WebRTC.
- Codec2 uses a Rust encoding core. Five input formats and H.264, HEVC, and AV1 were verified. Capability enumeration and XML generation share the same snapshot, with four decoder and three encoder components.
- The Codec2 seccomp policy permits the logging socket and connect call. Cold-start and steady-state syscalls were checked against their actual arguments. Surface decoding and browser encoding have separate regression checks.
- The Rust Codec2 decoder delivers each display frame separately, caps startup and replay CSD at 2 MiB, and validates gralloc handles, metadata, and plane bounds. VP9 superframes were tested through ByteBuffer and Surface, along with 60 seconds of VP9 playback in Chrome.
- Multi-window mode (`persist.waydroid.multi_windows=true`) provides freeform app windows and a desktop window with KDE decorations.
- Host input method: text-input-v3 → `WaydroidHostIme`.
- Clipboard: ext-data-control receives host copies and passes them into Android through the input method. The host Python clipboard service was removed.
- File sharing: host `~/Downloads` appears as Android `Download/Host`. Change it through `shared_folders` in `waydroid.cfg`. Host changes are automatically indexed by the Android media library.
- Audio: output goes through host PulseAudio. AAudio streams such as web audio work with MMAP disabled. Android defaults to maximum media volume and the host controls output volume.
- Widevine: L3 (`dumpsys android.hardware.drm.IDrmFactory/widevine` reports `default_security_level: L3` and `hdcp_level_max: Unprotected`). The security level cannot be raised.
- Root: KernelSU LKM, Local Signature Manager 32708.
- ABIs: `x86_64, arm64-v8a, x86`. ARM translation uses ATV's `libndk_translation`, with no `armeabi-v7a` support.

## Tests and follow-up

1. **Heavy workloads.** 3DMark Wild Life Extreme (Vulkan, 4K) scored 12,287–13,096, or about 74 FPS. Repeated runs in one process stayed stable with no Xid errors. Basemark GPU (Vulkan 1.0, 4K, Medium, offscreen, Z Prepass off) scored 35,657 on the host driver (BC7) and 29,369 in Waydroid (ETC2), about 82%. Actual 3D games have yet to be tested.
2. **Track the upstream libvulkan fix.** The Android 17 loader's R8G8B8 swapchain check directly calls the Vulkan 1.1 function pointer `GetPhysicalDeviceImageFormatProperties2`. It crashes when the pointer is null in a Vulkan 1.0 instance. This repository works around it by having gralloc stop advertising BGR888 as renderable (`patches/external_minigbm/0009`). The loader fix is pending review at [LineageOS Gerrit 509993](https://review.lineageos.org/c/LineageOS/android_frameworks_native/+/509993) and was reported to Google as [b/577380015](https://issuetracker.google.com/issues/577380015).
3. **Preflight the next release gate.** Check for `dump.erofs`, `debugfs`, `readelf`, `unshare`, and other required tools before running the gate. Report the corresponding Arch package when a tool is missing to avoid a bare `Errno 2`.

## Out of scope

- **Rebasing on every waydroid-nvidia release.** This fork builds its own dual-queue NVK and vendor image and carries host patches. Port applicable upstream fixes individually, especially when a driver update fails the gate. All applicable fixes through v0.2.0 have been ported, covering the host, hwcomposer, RM ZCULL and TSG, the NVK compute queue family, and the driver version table. Skipped commits are recorded in `.agents/skills/waydroid-a17-upstream/references/upstream-ignore.txt`. Evaluate new ATV system images separately. Codec2 decoding, its capability table, and XML generation now use Rust, so corresponding C++ fixes need to be rewritten. See `reports/codec2-rust.md`.

- **32-bit ARM (`armeabi-v7a`).** Most apps now have arm64 builds. Google Play has long required 64-bit support and newer phones have dropped 32-bit app support. ATV's Android 17 image only includes arm64 translation. The `16arm_16arm64` branch of ATV's `vendor_google_proprietary_ndk_translation-prebuilt` contains 32-bit libraries for Android 16.
- **Showing the desktop and individual app windows at the same time.** Both modes share one Android display. Individual windows and host menu entries cover everyday use. Switch to the desktop temporarily for widgets or apps that work poorly in individual windows.

## Known issues with individual windows and input methods

1. **Individual windows share one Android display.** The display size includes 200 units of headroom beyond the host size. When many windows are open, they can overlap and intercept clicks.
2. **Inline preedit stays in the candidate popup.** With inline preedit enabled via Ctrl+Alt+P in Fcitx 5, pinyin still appears only in the candidate popup in Android and KWrite. The behavior is on the Fcitx 5 or KWin side.
