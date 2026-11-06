---
name: waydroid-a17-test
description: Test this project's Waydroid Android 17 NVIDIA stack on the author's machine — restart the session, run commands in the guest, try a module through the vendor overlay, NVDEC/NVENC Codec2 regression, Chrome WebCodecs/WebRTC hardware-encode check, graphics/HWUI checks and screenshots of Android windows. Use for guest-side debugging, regression checks, or verification inside Waydroid.
---

> Translated from Chinese.

# Test

Machine: RTX 4060 Laptop, nvidia-open 615.78.08, KDE Plasma Wayland. NVIDIA rendering node `/dev/dri/renderD129` (`renderD128` is AMD identification).
Script is in `.agents/skills/waydroid-a17-test/scripts/` (below `$T`). Script reading `SUDO_ASKPASS` is required for sudo.

## Sessions and Containers

```bash
$T/session-restart.sh                 # Backstage start and wait until ready; front desk `waydroid session start` will not return
$T/guest.sh 'logcat -d -s nvc2 nvc2-enc | tail'   # root shell in the container
```

- Packaging `/data` = host `~/.local/share/waydroid/data`, and the push file is copied directly to `.../data/local/tmp`.
- Application: `waydroid app launch <package-name>`; web page: `waydroid app intent android.intent.action.VIEW <url>`.
- Graphic confirmation: `$T/guest.sh 'dumpsys SurfaceFlinger | grep GLES:'` should be ANGLE — NVK (RTX 4060).
- `dmesg | grep -i xid` There should be no new NVIDIA Xid.

## Overlay Try Single Modules

`sudo install` to `/var/lib/waydroid/overlay/vendor/<relative-vendor-path>`, and `session-restart.sh`. `/vendor/odm` Under
Service homogeneity (`overlay/vendor/odm/bin/hw/`, group 2000,0755). Checking out what's in overlay: delete all before release
（ `sudo find /var/lib/waydroid/overlay/vendor -type f` ）。 `media_codecs_c2.xml` Not in overlay: It's by host
`/var/lib/waydroid-nvidia/vendor-image/` Just read it in and change the encoder list from XML and `install.json`.
`media.xml_sha256`/ `codecs`, otherwise the service start-up validation failed.

## Decrypt Returns

```bash
make -C "$WS/nvidia/waydroid-nvidia/nvidia-prolapse/media" c2-smoke c2-enc-smoke   # First
CODEC_SMOKE_OUT=/tmp/codec-evidence $T/codec-smoke.sh
```

Expected results: 60 frames and zero bad buffers for each of four decoders, and 60 frames in and out for each of three encoders. Host FFmpeg must decode without errors. H.264 uses Constrained Baseline.
Encoder switch `persist.waydroid.nvidia_video_encode`, decoder switch `persist.waydroid.nvidia_video_decode` (`waydroid prop set`).
The script creates decoders by component name and records every client, FFmpeg, and ffprobe exit status. It requires 60 frames and zero bad buffers from each decoder, 60 frames in and out from each encoder, 60 frames reported by host ffprobe, and no FFmpeg errors. It also tests full replay after flushing, destruction with pending work, and a malformed input of 128 bytes of 0xff. The last case must produce zero images and either EOS or a clear error. Run each negative test separately with `CODEC_SMOKE_FAULT=client-failure|wrong-name|truncated|bad-buffer`. Each must exit nonzero. The bad-buffer case injects an empty buffer into the first client frame. The output directory preserves raw logs and exit codes. For host C encoder timings, run `M/test/enc-benchmark.py OUT`. It discards the first 30 of 330 frames and alternates the order across five runs, producing per-frame CSV and summary JSON.

VP9 Multiple frames regression: `make -C "$WS/nvidia/waydroid-nvidia/nvidia-prolapse/media" superframe-test` Generate `out/host/superframe/{vp9.mp4,pair.bin}`,
Runs after the host verifies 59 input, 60 frames and incompile/final events. Puts both files in the same directory as the new client:
`./c2_smoke vp9.mp4 c2.nvprolapse.vp9.decoder superframe pair.bin`、
`./c2_surface_smoke vp9.mp4 c2.nvprolapse.vp9.decoder pair.bin`。
Both have to report `superframe: 2 outputs at shared PTS, total=60`; Surface has 59 input, 60 output, 60 image, EOS, 0 error.

### Surface and seccomp windows

```bash
$T/surface-smoke.sh /tmp/surface-evidence
CODEC_SMOKE_OUT=/tmp/seccomp-evidence/clients \
  $T/seccomp-check.sh /tmp/seccomp-evidence \
  "$WS/nvidia/waydroid-nvidia/nvidia-prolapse/media/odm/etc/seccomp_policy/android.hardware.media.c2@1.2-nvprolapse.policy"
```

Surface script compiled `c2_surface_smoke`, each of the four specified components asserts 60 input, 60 output, 60 PravATE image, EOS and normal destruction; each exit code is saved in `exit-codes.tsv`.
The second parameter of the seccomp script can be left empty (using the current policy), followed by a custom steady state load command, default running `codec-smoke.sh`. The cold window is suspended by init `ctl.sigstop_on` before exec, anatach is restored and awaits Store; a steady state window atatach running the client. The successful non-NULL `PR_SET_SECCOMP` is used as a boundary, and the actual guest include is then rolled out, saves the syscald assembly before and after installation, uses the call-by feed and overlays the conclusion; the un overlayed, unknown parameter word or SIGSYS is failed and cannot be used as an alternative strategy comparison with the "No SIGSYS " .
Only ad hoc bind files are provided to check the Sigstop when deploying SHA256 EXIT, to close the service, to stop the service, to untie the bind, to restart the service and to check the original SHA256. The two scripts are shared `/tmp/wd-guest.lock`; the upper layer of the lock is called `WD_GUEST_LOCKED=1` to avoid the nesting locks.

## Chloe Hardware Encoding

```bash
WEB_ENCODE_OUT=/tmp/web-evidence $T/web-encode-test.sh 150
```

Opens the page only in the guest chrome. Each example is run UUID and standalone ID; POT requests the host to empty logcat before the page starts and waits to confirm that, immediately after POSS JSON, the host files the window log. WebCodecs four strict requirements 60 output, key frame, no error; WebRTC three request frames > 0, width at least 960 x 540 and each window has an AVC/HEVC/ AV1 log open. The evidence directory contains each JSON, logcat, window opening time and total exit status; it is not zero.

## Screenshot and Desktop

- Find and set windows with `kde_window` list/activate/place to intercept full screens; apply a KDE window to each Andre in multiwindow mode,
  Title `waydroid.<package-name>`. The entire Android desktop window is called `Waydroid`.
- The screenshot should be made public by looking at the content: the YouTube recommendation column, the notification, and the account number first image may be removed or changed with something that should not be made public.

## Host Chloe/Firefox

Clear drivers before startup: `env -u LIBVA_DRIVERS_PATH -u LIBVA_DRIVER_NAME -u NVD_BACKEND -u NVD_LOG`; experimentally use temporary profile
(`--user-data-dir=/tmp/...`), delete after exhaustion.

## Debug Switches

`setprop waydroid.dump_hal 1` (Next print layer, task, window); `waydroid prop set persist.waydroid.clipboard_debug true`
Restart Session (logcat) `hwcomposer` It's `clipboard:` Line. Clear the Waydroid Data and reset it. `/data/adb/ksud` KernelSU Manager
(`kernelsu/README.md` Step 5) and recommence `waydroid prop set persist.waydroid.multi_windows true`.
