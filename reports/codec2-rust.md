> Translated from Chinese.

# Porting Codec2 to Rust

The guest Codec2 service `android.hardware.media.c2@1.2-service-nvprolapse` now performs its media processing in the Rust RM backend.
The change shipped in `a17-20261028-2`. The host VA-API driver rustnv uses the same RM video code.

## How the code is split

In this report, `M` means `nvidia-prolapse/media` and `N` means `nvidia-prolapse/driver-source/native`. Both are in the `a17-local` branch of `nvidia/waydroid-nvidia`.

|Part|Location|Languages|
|---|---|---|
|Codec2 components, parameters, Store, service portal|`M/c2/NvC2Component.cpp`、`NvC2Encoder.cpp`、`service.cpp`|C++|
|Encoding session thin layer|`M/core/nvc2_encoder.{h,cpp}` → `nv_venc_sess_*`|C++ shell, approximately 100 lines|
|Encoding: Sessions, Code Controls, Five Input Conversions, SSE2 Fractures|`N/src/video/{venc,ffi_enc}.rs`, `enc/`, header `N/video/nv_venc.h`|Rust|
|Decoding driver: Queue, play back CSD, multi-screen frame, Flush/ EOS, gralloc check|`N/src/video/{c2_dec,ffi_dec,c2_layout}.rs` Header File `N/video/nv_c2_dec.h`|Rust|
|Capability table with `media_codecs` XML, `nvc2-xmlgen`|`N/src/video/{caps,ffi_caps}.rs` Header File `N/video/nv_c2_caps.h`|Rust|

C++ handles the parts required by Android's Codec2 interface: component lifecycle, parameter reflection, C2 buffer access, and validation of the outer gralloc native handle.
All exported Rust functions have panic boundaries. ABI layout assertions cover 32-bit and 64-bit builds on both the C and Rust sides.

## Differences from Shiro836/waydroid-nvidia

rc11(`7670f54`), under `M` these documents have been deleted and replaced by the Rust code in the table above:

- `core/nvc2_decoder.{h,cpp}`: Decoding driver.
- `core/nvc2_caps.cpp`, `tools/nvc2_xmlgen.cpp`: Capability table and XML generation.
- `test/core_test.cpp`, `test/xml_test.cpp`, `test/nv_video_stub.{h,cpp}`: Test moved into RM (false backend, 30 decoding/ layout test).

Also `c2/NvC2Component.cpp`, `service.cpp` replace with a call for Rust ABI; the encoder (`NvC2Encoder`, `nvc2_encoder`) is added to this repository and is not upstream.

Approaches to upstream restoration of transplants:

- For upstream changes to `nvc2_decoder.cpp`, `nvc2_caps.cpp`, or xmlgen, port the fix into the corresponding Rust source.
- Merge upstream `c2/` component changes manually, preserving calls to `nv_c2_dec_*` and `nv_c2_caps_*`.
- Merge other RM changes under `N/src` normally.

## Handling added during the port

- Individual VP9 Input multi-screen frame delivery: non-last frame `FLAG_INCOMPLETE` clone, the last frame completes the original work.
- CSD (decoding special data for start-up and playback) has a maximum of 2 MiB per segment, which is more than total rejection and reporting `C2_BAD_VALUE`.
- The gralloc handle first verifies the outer layer (versions, fds, words) in C++, and then Rust checks the format, geometry, stride, offset, plane scope and overlap.
- MaxInputSize uses checked 64-bit arithmetic. An overflow rejects the new value and retains the previous one.

## Performance

The workload was 1280×720 NV12 at 30 FPS. Each run processed 330 frames and discarded the first 30. The old and new implementations alternated for five runs each. Results are the median in milliseconds per frame.
Timing includes submission and waiting and excludes file I/O and encoder startup and shutdown.

|Encoding|Code|Version C|Rust version|Change|
|---|---|---:|---:|---:|
|H.264|CQP|0.591|0.597|+0.98%|
|H.264|CBR|0.637|0.609|−4.38%|
|HEVC|CQP|0.455|0.443|−2.51%|
|HEVC|CBR|0.461|0.455|−1.31%|
|AV1|CQP|0.481|0.479|−0.50%|
|AV1|CBR|0.497|0.500|+0.74%|

Four out of six are slightly faster, up to 4.4 per cent, while the remaining two are less than 1 per cent slow and fall within the range of measuring fluctuations.
Across the five input formats and three codecs, the lowest PSNR was 39.5 dB, matching the C version.
Decoder validation covered correctness. All 60 frames matched for each of four codecs, and Chrome played 60 seconds of VP9 with zero dropped frames.

The capability table and XML were replaced with Rust, GNU/Bionic, four new and old XML outputs were identical by bytes, and the installation record `media.xml_sha256` remained unchanged.

## Regression tests

All in `waydroid-a17-test` skill: `codec-smoke.sh` (including VP9 example), `surface-smoke.sh`, `web-encode-test.sh`,
`seccomp-check.sh` (cold startup and steady state two windows based on a cross-reference strategy). Encoding timer `M/test/enc-benchmark.py`.
