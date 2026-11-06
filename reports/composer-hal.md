> Translated from Chinese.

# Composer HAL and Wayland port reports

## Delivery

Only stand-alone cloning under `nvidia/work/`; no access to synchronous `src/`, no push.
The branches of both warehouses are `nvidia-a17` and the work tree is clean.

|Repository|Baseline|Port submission|
|---|---|---|
|`nvidia/work/hardware_interfaces`|WayDroid-ATV/android_hardware_interfaces，lineage-24.0，`1b0bcde9a85bd3e6c5866ae83aaab9af9b5efd29`（depth 200）|`7c6466bcb5ab93c039bd69db084e9c961610acc1`|
|`nvidia/work/wayland-protocols`|TUNA AOSP platform/external/wayland-protocols，android-17.0.0_r1，`2dabfe6879b25981e0340823eb1b6d037d21577f`（depth 1）|`782480c88f3b8682cf88b63144f9b7220a963f06`|

## Patch application results

### Hardware/interfaces/0001: clean application of the original path, supplementary to A17 semantic matching

Import in `git am -3`, keep the original author of Shiro836, and submit the message in original English, with an additional Chinese approximation; no patches have been discarded.

- A17 Retain `graphics/composer/2.1/utils/hwc2on1adapter/HWC2On1Adapter.cpp` with 2.1 `ComposerClient.h` and the original patch does not need to be rerouted.
- Release the adaptor `mStateMutex` to `shared_ptr<Display>` to keep the object alive and to avoid a reversal of the lock order of the validate/present when the `populateConfigs()` call.
- Keeps the player/clit-target cache while reconnecting; same and non-zero cliet-target lot count returned successfully. Declaration, realization and display share_ptr containers are confirmed to exist.
- **Android 17 compatibility.** ATV ships both the 2.1 and 2.4 services. The 2.4 `ComposerClient` inherits from 2.3, 2.2, and 2.1 but overrides `HalEventCallback::onHotplug`, so the 2.1 change alone does not protect it. The same port extends buffer-cache retention to 2.4. The slot-count method still comes from 2.1. Service selection and the other 2.4 callbacks were preserved.

### External/wayland-protocols/0001: need to resolve baseline conflict

The ATV `hardware_waydroid/hwcomposer/Android.bp:43-47` static dependence `libwayland_extension_client_protocols`. This module is defined by AOSP `external/wayland-protocols/Android.bp`, where Scanner enters freedesktop.org XML filegroup; is not a copy of 1.49 that is attached to the hwcomposer warehouse. The filegroup has listed the seven XMLs that are required and does not need to modify the building rules.

PortHwcomposer confirmed the generated header dependencies for patches 0001 and 0014. Lines 58 and 67 of the protocol Android.bp list the linux-dmabuf and xdg-decoration XML files. `wayland_extension_client_protocol_headers` runs `wayland_scanner client-header` and writes `$(in:base)-client-protocol.h`. `libwayland_extension_client_protocols` exports the output through `export_generated_headers`. The rules generate `xdg-decoration-unstable-v1-client-protocol.h` and `linux-dmabuf-unstable-v1-client-protocol.h` with the v4 feedback interface. The static check of the rules and XML found no need for further Android.bp changes. The scanner and build were still pending.

The seven files of Android 17 tag exist, but the versions/contents are inadequate, especially the dmabuf feedback:

|XML|AOSP android-17.0.0_r1|After transplant (the 1.49 content of the original patch)|
|---|---|---|
|presentation-time|presentation/feedback v1|v2|
|viewporter|v1|v1, update normative text|
|xdg-shell|v3|v7|
|linux-dmabuf-unstable-v1|v3, no feedback interface|dmabuf/params/feedback v5, including hwcomposer requirements v4 feedback|
|pointer-constraints-unstable-v1|v1|v1, update normative text|
|tablet-unstable-v2|Interface version v1|Interface version v1, update regular text|
|xdg-decoration-unstable-v1|v1|v2|

Execute `git am -3` first, because the old object is not available for shallow cloning and partly in different contexts, it is not possible to build a triad ancestry; then apply hunks, manually merge the remaining context, then `git am --continue`. Retain the original author ' s waydroid-nvidia project, original English message, and add an additional explanation in Chinese.

Solves: A17 has dmabuf hotplug-in error, hidden modifier description and presentation list entries split to avoid adding; merges the xdg_surface role check description and completes the modifier v4 waste description, interpretation `presented` synonyms and terminology updates. The last seven XML git blob SHA-1 accurately match the original patch target index (not only the interface version), XML interprets all. The other protocols have not changed to the ATV feature.

## Init / VINTF service reconciliation

The static source code indicates that init will try to start two coposer services, and cannot claim to start only one of them when running:

- `device_waydroid/device.mk:78-79` Pack `android.hardware.graphics.composer@2.1-service` and `@2.4-service`.
- The Android.bp of both modules are installed accordingly init rc; rc defines `vendor.hwcomposer-2-1`, `vendor.hwcomposer-2-4`, each `class hal animation`, does not have `disabled` or `oneshot`; 2.1 states otherwise `interface android.hardware.graphics.composer@2.1::IComposer default`.
- `device_waydroid/manifest.xml:80-85` Declarations `@2.1::IComposer/default` and `@2.4::IComposer/default`. VINTF declarations themselves are not responsible for selecting the start-up process.
- Both service. cpps try `HwcLoader::load()` and `registerAsService()` and fail to return 1. Which version is actually registered successfully, which version SurfaceFlinger binds, and whether there is a reboot/absorption, must be observed after start-up; no surmise is used to replace the physical measurements and no changes are made to the existing service strategy.

## Self-checked

- Two warehouses `git diff --check HEAD^ HEAD` no output; `git status --porcelain=v1` no output.
- The modified Composer 2.1/2.4 file does not conflict with the protocol XML tag.
- Read relevant locks, echoes and inheritance codes; confirm by symbol that `populateConfigs()`, `getDisplayClientTargetCacheSize()`, `mDisplays` shared_ptr containers exist.
- All seven XMLs are parsed and accurately match the original patch target blob.
- No construction, project test or equipment running test (source tree not yet ready).

## Runtime validation

1. Check whether the registration is repeated or replaced with `getprop init.svc.vendor.hwcomposer-2-1`, `getprop init.svc.vendor.hwcomposer-2-4`, process list, `lshal` and start-up log to confirm that the actual service registration is tied to SurfaceFlinger.
2. Continuous reze, maximization/reducing while playing or rendering NVIDIA/KWin; confirmation that the master displays a resize with no dead lock, BAD_LAYER, use after release or SurfaceFlinger/HAL crash.
3. The clit-target lot count that confirms the new display can be repeated; the old player cache is released with destroyLayer, and the clit-target handles are updated with slot to release long time resize without accumulated resources.
4. Authentication of dmabuf v4 feedback devices and format/modifier parsing, both directly with GPU and across GPU PRIME-copy; the new XML can be negotiated with the lower version of the host.
5. Verifys the behaviour of presentating Timing, viewporter crop, xdg-shell reze/ Decoration, Pointer constrainings and tablet input; retains ATV task books, multi-window and touchpad.
