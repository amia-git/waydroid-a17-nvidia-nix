---
name: waydroid-a17-upstream
description: Check this project's upstreams for changes against what it pins — Shiro836/waydroid-nvidia commits since the fork point, the WayDroid-ATV system image, the patch bases of the Android source repositories, the NVIDIA driver version against the nvrm ABI table, and the LineageOS Gerrit change for the libvulkan fix — then judge which upstream fixes are worth porting. Use before a release or when an NVIDIA driver update fails the gate.
---

> Translated from Chinese.

# Check upstream

Read-only: Script only `git fetch` waydroid-nvidia and query remote, without changing any warehouse. The upstream restoration is another thing, and the user decides to do it later.

```bash
.agents/skills/waydroid-a17-upstream/scripts/check-upstream.sh            # Let's go first.
.agents/skills/waydroid-a17-upstream/scripts/check-upstream.sh --no-fetch
```

Needs `gh` (received), `rg`, network. The workspace uses `$WAYDROID_A17_WS` and defaults to pick up the public upper level.

## Check what?

| Paragraph | Contrast | Staple Source |
|---|---|---|
| waydroid-nvidia | `a17-local` Upstream non-document submission after the forkpoint with `origin/main` | `nvidia/waydroid-nvidia` git history |
| ATV mirror | Newest mirror date for release and nails | `aur/waydroid-a17-nvidia-bin/waydroid-a17-nvidia.install` |
| Patch baseline | Upper branch header and baseline submission for each warehouse; AOSP 's wayland-protocols are released tabs more recent than `android-17*` | `waydroid-a17-build/references/patch-bases.md` |
| NVIDIA Driver | Loaded version, extra warehouse version, NVIDIA upfront tab in nvrm version table; upstream widroid-nvidia has version and we don't have version nvrm | `nvidia/nvrm/src/compat_data.rs` |
| Gerrit 509993 | Status and recent news | `TODO.md` Item 2 |

## How?

- **waydroid-nvidia**: This repository is fork, not full version rebase (`TODO.md` "do not do " ). Scripts list all non-document submissions up to the fork point.
  Some of them have already been transplanted: `a17-local` submit in Chinese the header, git does not recognize the equivalent, judging diff.
  - Worth transplanting: nvrm version table, hwcompoper fix, setup/ installation fix, NVK repair effective for Ada.
  - The NVK modification and the two queues for this repository NVK are coded and have been transplanted and run dEQP subsets and 3Dmarks.
  - Not transplanted: glibc-shim, Venus/virglrenderer, NAK restoration for Blackwell only, upstream README and distribution instructions.
  - Decoding of Codec2 / Capability Table / XML has been replaced with Rust, and the corresponding C++ restoration upstream is rewritten in Rust (`reports/codec2-rust.md`).
- ATV has a new system image: a separate assessment, and a new mirror has to rerun the full regression suite.
- Patch baseline: Upstream, if new submission is made, to see if we have fixed the problem; re-export `patches/` and update `patch-bases.md` after changing base.
- Driver version is not in nvrm version table: this driver is upgraded to match nvrm (`tools/generate-compat.py`) and is recreated for vendor and rustnv,
  Both sides of the distribution; do not upgrade the driver. The same large version usually contains only `VERSIONS` line pointing to the existing profile.
- **Gerrit**: After the merge, A17's loader fixes into the system image, `patches/external_minigbm/0009` this bypass can be evaluated and removed.

The check results are orally communicated to the user; the logs in `TODO.md` are updated after the transplant has been completed.
