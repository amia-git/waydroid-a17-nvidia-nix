> Translated from Chinese. The original template paired each English entry with a Chinese translation.

# Release notes format

Use the previous release as a template. View its notes with `gh release view PREVIOUS_TAG --json body -q .body`.

```markdown
LineageOS 24.0 (Android 17) Waydroid vendor image, nvidia-prolapse mode.

- Pairs with the WayDroid-ATV `lineage-24.0-20261017` system image (VANILLA or GAPPS). Arch users can install the AUR package `waydroid-a17-nvidia-bin`.

Changes since `PREVIOUS_TAG`

- Describe the changes users can see.

Release gate PASS (22 cases plus media, NVIDIA kernel module VERSION).

The image is uploaded in parts. Combine and decompress them with this command.

    cat vendor.img.zst.part* > vendor.img.zst && zstd -d vendor.img.zst

See `vendor.img.zst.sha256` for the checksums of the parts, archive, and extracted image. The matching native driver bundle is `waydroid-a17-nvidia-native-x86_64.tar.zst` (bundle name BUNDLE_NAME).
```

Describe user-visible changes and name the source of upstream ports, such as waydroid-nvidia rc11.
