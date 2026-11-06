> Translated from Chinese.

# Patch baseline

`patches/<directory>/` is a submission from each local branch of the warehouse above the following baselines (`git format-patch`), in a numbered order `git am`.

| Contents | Inside Path | Upper | Branch | Baseline | Number of patches |
|---|---|---|---|---|---|
| `hardware_waydroid` | `hardware/waydroid` | https://github.com/WayDroid-ATV/android_hardware_waydroid | lineage-23.0（ATV manifest） | `3af187c1de51` | 34 |
| `external_minigbm` | `external/minigbm` | https://github.com/WayDroid-ATV/android_external_minigbm | lineage-24.0 | `5f5797cacd14` | 9 |
| `hardware_interfaces` | `hardware/interfaces` | https://github.com/WayDroid-ATV/android_hardware_interfaces | lineage-24.0 | `1b0bcde9a85b` | 1 |
| `external_wayland-protocols` | `external/wayland-protocols` | https://android.googlesource.com/platform/external/wayland-protocols | AOSP | `2dabfe6879b2` | 3 |
| `device_waydroid_waydroid` | `device/waydroid/waydroid` | https://github.com/WayDroid-ATV/android_device_waydroid_waydroid | lineage-24.0 | `ce2f57ee2768` | 4 |
| `vendor_waydroid_init` | `vendor/waydroid/init` | https://github.com/WayDroid-ATV/android_vendor_waydroid_init | main | `e97b43d97f70` | 2 |
| `waydroid-nvidia` | `../nvidia/waydroid-nvidia` | https://github.com/Shiro836/waydroid-nvidia | public-test | `29ffa3a237b0` | 73 |

`waydroid-nvidia` The AUR package is used in prepare() to hit `git apply` (the patch contains a binary test stream) and requires
`GIT_CEILING_DIRECTORIES` Otherwise you skip all paths silently while running makepkg in the git warehouse.

From zero: `podman build --build-arg ROOT="$WS" -t localhost/waydroid-a17-build container` (Building packagings to mount working areas by their original path,
Mesa cross-composes the ld in the tree →  `scripts/sync.sh` →  `apply-waydroid-patches` →  warehouses `git am` →  `scripts/stage-product.sh`
`scripts/build.sh lineage_nvidia_waydroid_x86_64-cp2a-userdebug vendorimage`. The source code is about 100 GB.
