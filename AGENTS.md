# AGENTS.md

This fork packages Android 17 Waydroid with NVIDIA acceleration for NixOS. The upstream Android and NVIDIA integration comes from [waydroid-a17-nvidia](https://github.com/cagedbird043/waydroid-a17-nvidia).

- Keep NixOS installation and update instructions in the main README. The flake, package, and NixOS module define how this fork is installed.
- Keep upstream source patches, Android build tooling, and technical reports available for debugging. The Nix package uses the host patch series and KWin script in this repository, plus pinned upstream release assets.
- Run `nix flake check --no-update-lock-file --print-build-logs` for packaging changes. Check Android boot and GPU behavior on suitable hardware when a change affects them.
- Use English and Conventional Commits. Push and publish only when requested. Publish GitHub source releases for this fork after verifying the tagged Nix package builds.
