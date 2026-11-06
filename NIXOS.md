# Waydroid A17 NVIDIA on NixOS

The flake exports a NixOS module and an x86_64 Linux package. The module uses NixOS's Waydroid service and LXC configuration with the upstream NVIDIA-patched Waydroid, its matching vendor image, and the GPU compatibility check. Use a Wayland session on an x86_64 machine with NVIDIA's open kernel modules and DRM modesetting enabled.

## Add the module

In your system flake, add this input:

```nix
inputs.waydroid-a17-nvidia.url = "github:ariaofdelusion/waydroid-a17-nvidia";
```

Add these entries to your host's `modules` list. This assumes your flake's `outputs` function exposes the input set as `inputs`.

```nix
inputs.waydroid-a17-nvidia.nixosModules.default
{
  virtualisation.waydroid-a17-nvidia.enable = true;
}
```

The module uses your system's nixpkgs and existing NVIDIA configuration. The standalone `nix build .` uses this flake's locked nixpkgs.

## Initialize Android

Download the x86_64 VANILLA or GAPPS system ZIP and the MAINLINE vendor ZIP from [WayDroid-ATV 20261017](https://github.com/WayDroid-ATV/waydroid-builds/releases/tag/20261017). On an existing Waydroid install, back up `/var/lib/waydroid` and any preinstalled images before switching Android versions.

From the directory containing the ZIPs, run:

```sh
bsdtar=$(nix build --no-link --print-out-paths nixpkgs#libarchive)/bin/bsdtar
sudo install -d /etc/waydroid-extra/images
sudo "$bsdtar" -xf lineage-24.0-20261017-VANILLA-waydroid_x86_64-system.zip -C /etc/waydroid-extra/images system.img
sudo "$bsdtar" -xf lineage-24.0-20261017-MAINLINE-waydroid_x86_64-vendor.zip -C /etc/waydroid-extra/images vendor.img
sudo waydroid init -f
sudo waydroid-nvidia-setup
waydroid session start
```

Use the GAPPS system ZIP filename in the first extraction command if you chose GAPPS. The setup command tests the packaged NVIDIA vendor image against your GPU and loaded driver before installing it. It keeps the original vendor image for `sudo waydroid-nvidia-setup --restore-official-vendor`. Run setup again after updating the NVIDIA driver or this package. The NixOS port packages the upstream nvidia-prolapse mode. KernelSU remains a separate host-kernel setup.
