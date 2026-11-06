---
name: waydroid-a17-release
description: Release a new version of waydroid-a17-nvidia — version the release, sync product/patches/docs, package the split vendor image and native bundle, install the local AUR package and pass the release gate, regression-test, then tag, create the GitHub release and update the AUR package waydroid-a17-nvidia-bin. Use for release preparation, AUR updates, and release gate failures.
---

> Translated from Chinese.

# Release

Only when the user explicitly states the release; push,tag, Release, AUR are all external actions. Script is in `.agents/skills/waydroid-a17-release/scripts/` (hereinafter `$R`).

tag `a17-YYYYMMDD-N` N, pkgver `YYYYMMDD.N` . The name of the active bundle `v0.2.0-rc11-a17-<suffix>` 。

## Process

1. Build: `waydroid-a17-build` Scill's `build-vendor.sh` (native) `rebuild-native.sh` ) In
   `nvidia/product`, `nvidia/waydroid-nvidia` submitted; synchronized `nvidia-product/` and `patches/`.
2. Document: functionality/change for README, status `TODO.md`.
3. Submit version number: `$R/package.sh <tag>` Change PKGBUILD `_tag` / `pkgver` exit after first change; change it and step 1, 2
   Submitted together as `Release <tag>: <one-line summary>` (emphasis box).
4. Packet: `$R/package.sh <tag>`: Compressed fragment mirrors, play bundle, put in `aur/waydroid-a17-nvidia-bin/`, `makepkg`.
   Blocks default by 5 MiB, the quantity must be equal to PKGBUILD `_vendor_parts` (the script will be checked); only the compressed mirror is available `package.sh <tag> --resplit`, and no mirror or native bundle can be recreated. `VENDOR_PART_SIZE` The size of the block may be specified.
5. Install + release gate: `$R/install-gate.sh <pkgver>`. See `Release gate PASS: 22 cases + media` and
   `Installed the nvidia-prolapse vendor image <bundle-name>`
6. Returns (`waydroid-a17-test` skill): Sessions rise, GLES is ANGLE/NVK, `codec-smoke.sh`, `web-encode-test.sh`,
   Add this version to the relevant scene (cards, desktop windows, input methods, clipboards, file sharing, KernelSU).
7. Push: `git tag <tag> && git push origin HEAD <tag>`.
8. **Release**: Build the draft and then upload it one by one (`gh release create` when any uploading of the assets is broken, the whole Release will be deleted),
   If you break it, you run again to the same file. `--clobber` ：
   ```bash
   gh release create <tag> --draft --title "vendor <tag>" --notes-file <release-notes-file>
   for f in vendor.img.zst.part[0-9][0-9] vendor.img.zst.sha256 waydroid-a17-nvidia-native-x86_64.tar.zst; do
       gh release upload <tag> "$f" --clobber
   done
   gh release edit <tag> --draft=false --latest
   ```
   For description format see [references/release-notes.md](references/release-notes.md).
   `gh api repos/cagedbird043/waydroid-a17-nvidia/releases --jq '.[] | select(.draft) | .assets[] | "\(.digest) \(.name)"'`
   For local `sha256sum` comparisons, the asset number must be `_vendor_parts + 2` (blocking, verification form, native bundle).
9. **AUR**: `$R/aur-publish.sh <tag>` (Release must have been released): Checking and taking GitHub API records of Release assets `digest`,
   Do not download;tag/committee source package is played by GitHub now, Hashi is different from the local `git archive`, and is calculated after download. Generate `.SRCINFO`,
   Submit `AUR: checksums and .SRCINFO for <tag>` and send this repository and AUR.
10. Reporting: closed results, regression figures, submission numbers, Release links.

## The lockdown failed.

| Wrong report. | Reason | Processing |
|---|---|---|
| `nvrm (x86_64) was linked against libnv_bionic_native.so …` | Rust, it's not redacted. | `rebuild-native.sh`, again `build-vendor.sh` |
| `the installed package carries release bundle …, the vendor image …` | No running since the package was updated, setup | `sudo waydroid-nvidia-setup` |
| `has no ELF64 …/linker64` | AUR prepare 's `git apply` Skipped silently in the git warehouse | PKGBILD reserved `GIT_CEILING_DIRECTORIES` |
| Inconsistent service / `media/xmlgen-check` Failed | Service in mirror or XML different from bundle | Double-recording, no manual changes. |
| `can't open file …/media/tools/check-xmlgen-elf.py` | Script check for missing media door for common ELF | `install-native.sh` Install the script on the file list and repackage the doorbar |
| Failed to download upstream rc10 asset TLS | Network | Pickage.sh will copy the local copy from `$WS/nvidia/release/` |

## Rules.

- Not to push AUR: AUR before Release point to Release assets.
- The overlay must be empty before release (install-gate.sh deletes), otherwise it returns to overlay instead of mirrors.
- Release assets and makepkg downloads and products are in `.gitignore`, do not force gits.
- The Waydroid is managed by the pacman package `waydroid-a17-nvidia-bin`, `scripts/reinstall-vendor.sh` (go] `install.sh`)
  The document belongs to the pacman and is rejected; reloading is always complete.sh + install-gate.sh.
