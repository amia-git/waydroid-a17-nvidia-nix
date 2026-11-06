> Translated from Chinese.

# Issue #1: Missing EROFS tool dependency

## Diagnosis

- `gh issue view 1 -R cagedbird043/waydroid-a17-nvidia` shows that setup rolled back because it could not find `dump.erofs`.
- The workspace function `_dump_raw()` in `nvidia/waydroid-nvidia/packaging/native/release_gate.py:202-209` uses `dump.erofs --path=… --cat` on line 206. Line 266 uses `dump.erofs --path=… --ls`. The EROFS file could be system.img. The function also extracts the system runtime, so the error does not identify vendor.img as the file being read.
- `aur/waydroid-a17-nvidia-bin/PKGBUILD:46-47` downloads pinned upstream source and the release tag source. Lines `:118-123` apply the tag's `patches/waydroid-nvidia/*.patch` to upstream. At `:175-178`, `package()` invokes the patched `install-native.sh` with the source tree and native tarball.
- `nvidia/waydroid-nvidia/packaging/native/install-native.sh:32-47` copies source files such as `packaging/native/release_gate.py` and `vendor_image.py` into `/usr/lib/waydroid-nvidia/native/`. Lines `:53-55` extract the native tarball into `native/release/`. The Python gate comes from the AUR's pinned source and release patches. The bundle supplies the binaries, test programs, and data.

## Audit of external commands

The audit covers the vendor image release gate that the package actually runs (`vendor_image.py:268` calls `release_gate.run(..., vendor_image=new)`). It excludes the separate developer build workflow.

|Command|Arch package/source|Evidence|Dependence|
|---|---|---|---|
|`dump.erofs`|`erofs-utils`|`release_gate.py:206,266`|This Add|
|`debugfs`|`e2fsprogs`|`release_gate.py:209`；`waydroid/nvidia_native.py:1058`|As previously stated|
|`unshare`|`util-linux`|`release_gate.py:360` 32 bit test PID namespace|As previously stated|
|`python3`|`python`|`release_gate.py:450,558`|As previously stated|
|`readelf`|`binutils`|`nvidia-prolapse/media/tools/check-xmlgen-elf.py:14` (call from `release_gate.py:450`)|As previously stated|
|`nm`|`binutils`|`release_gate.py:578`|As previously stated|
|`linker` / `linker64`|Android system.img|`release_gate.py:349,355-357`|Not host Arch bag dependent|
|`vk-compute`, `vk-graphics`, `vk-interop`, `anb-roundtrip`, `astc-roundtrip`, `etc2-roundtrip`, `gl-triangle`, `gl-dmabuf`, `gl-skia-shaders`, `gl-yuv`, `nvc2-xmlgen`|`gate/bin/<ABI>/`|`release_gate.py:419-445,532-533`|Installation with package assets|

The packaged release gate had no other missing host-tool dependencies. The Bash staging and make smoke tests in `release_gate.py:482,494` belong to the developer workflow without a vendor image. The AUR setup uses Arch's systemd for `systemctl`, and `waydroid` comes from the package itself (`vendor_image.py:357,360,380-381`).

## Repair

- `pkgver` Hold `20261028.2`, `pkgrel=2`.
- `depends` Add `erofs-utils` to regenerate `.SRCINFO`; asset digest and tag remain unchanged.
- `TODO.md` records the plan to check for tools before running the gate and report the relevant Arch package when a tool is missing.

## Verification

- In clean `archlinux:latest` packagings, return 1 before `command -v dump.erofs` is installed; a separate second clean container returns 1 as well.
- `pacman -Sy` Straight back. `source /pkg/PKGBUILD` Here. `pacman -S --needed --noconfirm "${depends[@]}"` The installation of all operations depends on success; `pacman -Q erofs-utils` Yes. `1.9.4-1` ， `dump.erofs --help` Success. `pacman -Qo` Confirm the ownership of the above tools.
- Workspace log: `logs/issue-1-arch-dependencies.log`, `logs/issue-1-arch-without-erofs.log`. The default mirror server meets TLS EOF, TUNA encounters 403; the final clean container is installed using the USTC/Ari mirror, and the host Pacman configuration is not changed.
- This check covered dependency installation and tool execution. It did not run the full GPU release gate. The image, native bundle, release tag, and asset checksums were unchanged.
- `/tmp/codec2-inv-*` Deleted, glob confirmed no residues.
