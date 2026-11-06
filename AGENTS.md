> Translated from Chinese. This file describes the upstream release workspace and its conventions.

# AGENTS.md

`waydroid-a17-nvidia` is the upstream release repository for Android 17 on Waydroid with NVIDIA acceleration and KernelSU (`cagedbird043/waydroid-a17-nvidia`). The original author developed and tested it on one machine with an RTX 4060 Laptop GPU, NVIDIA open driver 615.78.08, KDE Plasma Wayland, and the Arch Linux Zen kernel.

## Repository and workspace

This repository is the `publish/` subdirectory of the `~/Projects/waydroid-a17` workspace. Source trees, build outputs, and native bundles live in the workspace. The release repository contains patches, a mirror of the product layer, scripts, documentation, AUR packaging, and generated release assets.

| Path | Contents |
| --- | --- |
| `README.md` | User-facing overview and installation instructions |
| `TODO.md` | Current status, plans, and known issues |
| `patches/<repository>/` | Patches exported with `git format-patch` from each source repository's local branch |
| `nvidia-product/` | Mirror of the workspace's `nvidia/product` tree |
| `scripts/` | Copies of the workspace scripts, intended to run from the workspace |
| `aur/waydroid-a17-nvidia-bin/` | AUR package |
| `kernelsu/`, `host/`, `container/` | KernelSU instructions, host services and KWin scripts, and the build container |
| `reports/` | Porting notes, comparisons, and benchmarks |
| `docs/images/` | README screenshots |

## Which skill to use

| Task | Skill |
| --- | --- |
| Build or rebuild the native stack, make bundles, and export patches | `waydroid-a17-build` |
| Verify changes, run regression checks, and capture screenshots in Waydroid | `waydroid-a17-test` |
| Prepare a release or AUR update | `waydroid-a17-release` |
| Review upstream changes and decide which fixes to port | `waydroid-a17-upstream` |

The skills live in `.agents/skills/`. The `.claude/skills` and `.codex/skills` paths are symlinks to that directory.

## Upstream release conventions

- The upstream workflow uses Simplified Chinese for replies and commit messages. Verify conclusions by testing and label unverified findings as speculation.
- Upstream delegates Git operations to AI, using the author identity `cagedbird043 <cagedbird043@gmail.com>` and omitting AI attribution.
- The allowed push targets are the upstream release repository, the AUR packages `waydroid-a17-nvidia-bin` and `nvrm-vaapi-driver`, and the workspace repositories `~/Projects/waydroid-a17/rustnv` and `~/Projects/waydroid-a17/nvidia/nvrm`. Commit workspace repositories under `src/`, `nvidia/waydroid-nvidia`, and `nvidia/product` locally. Push, tag, and publish releases only when requested.
- Leave the NVIDIA driver, kernel packages, boot settings (including `lsm=`), and the `@` subvolume alone. Avoid rebooting or logging out. Restarting the Waydroid session is allowed.
- The upstream workflow uses a temporary sudo askpass helper at `/tmp/wd-askpass` with mode 0700 and deletes it afterward. Keep passwords out of repositories, scripts, and documents.
- Changes to services, Rust libraries, or the product layer require the full two-pass build. Run the `waydroid-nvidia-setup` compatibility gate before releasing.
- Keep the README focused on users. Document development workflows in the relevant skill and avoid repeating them in the README or TODO.
- Review screenshots before publishing and exclude sensitive political material, account details, and notifications.
