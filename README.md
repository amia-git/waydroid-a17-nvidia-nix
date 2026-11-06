# Waydroid A17 NVIDIA for NixOS

Run Android 17 (LineageOS 24.0) in Waydroid with NVIDIA GPU acceleration. This fork packages the upstream NVIDIA integration as an x86_64 NixOS flake.

![NixOS](https://img.shields.io/badge/NixOS-flake-5277C3?logo=nixos&logoColor=white)
![Android 17](https://img.shields.io/badge/Android-17-3ddc84?logo=android&logoColor=white)
![NVIDIA](https://img.shields.io/badge/NVIDIA-NVK%20%2B%20NVDEC%20%2B%20NVENC-76b900?logo=nvidia&logoColor=white)
![NixOS port built with GPT 6.1 Sol](https://img.shields.io/badge/NixOS%20port-GPT%206.1%20Sol-412991)

## Install on NixOS

Add `github:ariaofdelusion/waydroid-a17-nvidia` as a flake input, import its `nixosModules.default`, and enable the module in your host configuration:

```nix
virtualisation.waydroid-a17-nvidia.enable = true;
```

Follow the [NixOS setup guide](NIXOS.md) to choose an Android system image and run the GPU compatibility check. You’ll need an x86_64 host, a Wayland session, and NVIDIA’s open kernel modules with DRM modesetting enabled. To build the package from a checkout, run `nix build .`.

## About this fork

The module uses NixOS’s Waydroid service with the upstream patched host package and matching vendor image. Upstream’s NVIDIA stack provides Vulkan and GLES through NVK, plus hardware video decoding and encoding through NVDEC and NVENC. The NixOS package builds successfully, and boot and GPU acceleration on NixOS still need hardware verification.

GPT 6.1 Sol built the NixOS port. The original project and its contributors built the Android and NVIDIA integration. See the [upstream project](https://github.com/cagedbird043/waydroid-a17-nvidia) for Arch Linux instructions, screenshots, benchmarks, and full acknowledgements.
