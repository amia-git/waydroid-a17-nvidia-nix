{
  lib,
  stdenvNoCC,
  fetchurl,
  runCommand,
  waydroid,
  bash,
  binutils,
  coreutils,
  e2fsprogs,
  erofs-utils,
  findutils,
  gawk,
  gnugrep,
  gnused,
  git,
  kmod,
  lxc,
  makeWrapper,
  python3,
  runtimeShell,
  systemd,
  util-linux,
  zstd,
  withNftables ? true,
}:
let
  version = "20261031.2";
  tag = "a17-20261031-2";
  hostRev = "29ffa3a237b0d79a751748bd9bb82c50dd577808";
  waydroidRev = "a33a5c0b31d89d6ce687381104b30aff4dd2d330";
  release = "https://github.com/cagedbird043/waydroid-a17-nvidia/releases/download/${tag}";
  nativeBundle = fetchurl {
    url = "${release}/waydroid-a17-nvidia-native-x86_64.tar.zst";
    sha256 = "01f17b394171deefe1d05da3965b1271f7ac745234aa27bd70cb39e0aca803d4";
  };
  vendorParts = lib.imap0 (index: sha256: fetchurl {
    url = "${release}/vendor.img.zst.part${lib.fixedWidthNumber 2 index}";
    inherit sha256;
  }) (import ./vendor-hashes.nix);

  patchedHost = runCommand "waydroid-nvidia-host-source-${version}" {
    nativeBuildInputs = [ git ];
    src = fetchurl {
      url = "https://github.com/Shiro836/waydroid-nvidia/archive/${hostRev}.tar.gz";
      sha256 = "4dc67241bf35189d4490306611f7f52e49117d04511a60999e96328f010dd84f";
    };
  } ''
    mkdir -p "$out"
    tar -xf "$src" -C "$out" --strip-components=1
    cd "$out"
    for patchFile in ${../patches/waydroid-nvidia}/*.patch; do
      git apply --whitespace=nowarn "$patchFile"
    done
  '';

  payload = stdenvNoCC.mkDerivation {
    pname = "waydroid-a17-nvidia-payload";
    inherit version;
    dontUnpack = true;
    dontFixup = true;
    nativeBuildInputs = [ bash e2fsprogs python3 zstd ];
    installPhase = ''
      runHook preInstall
      mkdir native ota "$out"
      tar --zstd -xf ${nativeBundle} -C native ./BUILD-RECORD.json
      cat ${lib.concatStringsSep " " vendorParts} | zstd -d -o vendor.img
      python3 ${patchedHost}/packaging/vendor-ota.py vendor.img native/BUILD-RECORD.json ota \
        --tag v0.2.0-rc10-a17 --repo cagedbird043/waydroid-a17-nvidia
      bash ${patchedHost}/packaging/native/install-native.sh \
        ${patchedHost} ${nativeBundle} ota/*.zip ota/*.json "$PWD/stage" v0.2.0-rc10
      mv stage/usr/lib/waydroid-nvidia/* "$out/"
      runHook postInstall
    '';
  };

  runtimeTools = [
    bash binutils coreutils e2fsprogs erofs-utils findutils gawk gnugrep gnused
    kmod lxc python3 systemd util-linux
  ];
  stock = waydroid.override { inherit withNftables; };
in
stock.overridePythonAttrs (old: {
  pname = "waydroid-a17-nvidia";
  inherit version;
  src = fetchurl {
    url = "https://github.com/waydroid/waydroid/archive/${waydroidRev}.tar.gz";
    sha256 = "e7817beac7e26f7d54b2d9f49c847dab8e137c92e403825829e7abbd0b63c411";
  };
  nativeBuildInputs = old.nativeBuildInputs ++ [ makeWrapper ];
  dontStrip = true;
  dontPatchELF = true;
  postPatch = ''
    patch -p1 < ${patchedHost}/patches/waydroid/0001-nvidia-integration.patch
    for patchFile in ${patchedHost}/waydroid/000[1-9]-*.patch; do
      patch -p1 < "$patchFile"
    done
    cmp ${patchedHost}/waydroid/nvidia_native.py tools/helpers/nvidia_native.py
  '';
  postInstall = ''
    libdir="$out/lib/waydroid-nvidia"
    mkdir -p "$libdir"
    cp -a ${payload}/native ${payload}/wd-native "$libdir/"
    chmod -R u+w "$libdir"
    ln -s ${payload}/vendor "$libdir/vendor"
    install -Dm755 ${patchedHost}/packaging/aur/waydroid-nvidia-bin/waydroid-nvidia-setup "$out/bin/waydroid-nvidia-setup"
    install -Dm644 ${patchedHost}/packaging/aur/waydroid-nvidia-bin/waydroid-nvidia-gpu.rules \
      "$out/lib/udev/rules.d/70-waydroid-nvidia-gpu.rules"
    mkdir -p "$out/share/kwin/scripts"
    cp -r ${../host/kwin-waydroid-placement} "$out/share/kwin/scripts/waydroid-placement"

    for helper in "$libdir/native/waydroid/nvidia_native.py" "$out/lib/waydroid/tools/helpers/nvidia_native.py"; do
      chmod -x "$helper"
      substituteInPlace "$helper" \
        --replace-fail /usr/lib/waydroid-nvidia "$libdir" \
        --replace-fail '"/usr/lib"' '"/run/opengl-driver/lib"' \
        --replace-fail '"/usr/lib32"' '"/run/opengl-driver-32/lib"'
    done
    substituteInPlace "$libdir/native/dev/source-native" \
      --replace-fail /usr/bin/python3 ${python3}/bin/python3 \
      --replace-fail "Path('/usr/lib/waydroid')" "Path('$out/lib/waydroid')" \
      --replace-fail "return [PYTHON, str(SYSTEM_WAYDROID / 'waydroid.py')]" "return ['$out/bin/waydroid']"
    substituteInPlace "$libdir/wd-native" \
      --replace-fail '#!/bin/bash' '#!${runtimeShell}' \
      --replace-fail /usr/lib/waydroid-nvidia "$libdir" \
      --replace-fail /usr/bin/python3 ${python3}/bin/python3
    substituteInPlace "$libdir/native/packaging/native/release_gate.py" \
      --replace-fail /usr/lib/waydroid-nvidia "$libdir" \
      --replace-fail '#!/bin/sh' '#!${runtimeShell}'
    substituteInPlace "$out/share/dbus-1/system-services/id.waydro.Container.service" \
      --replace-fail /usr/bin/waydroid "$out/bin/waydroid"
    substituteInPlace "$out/bin/waydroid-nvidia-setup" \
      --replace-fail '#!/bin/bash' '#!${runtimeShell}' \
      --replace-fail LIB=/usr/lib/waydroid-nvidia "LIB=$libdir" \
      --replace-fail '[ -d "$GUEST" ] || die "$GUEST missing (broken package?)"' "" \
      --replace-fail 'systemctl enable --now waydroid-container.service' 'systemctl start waydroid-container.service' \
      --replace-fail 'say "enabling and starting waydroid-container.service"' 'say "starting waydroid-container.service"' \
      --replace-fail 'if [ ! -f "$CFG" ]; then' $'[ -f "$CFG" ] || die "Initialize Waydroid with the Android 17 system and vendor images first."\nif [ ! -f "$CFG" ]; then' \
      --replace-fail 'MODE=$(REFRESH=' $'[ "$MODE_ARG" != venus ] || die "This package supports nvidia-prolapse mode."\nMODE_ARG=nvidia-prolapse\nMODE=$(REFRESH=' \
      --replace-fail 'and use the Venus mode meanwhile: sudo waydroid-nvidia-setup --mode venus' 'with the GPU check logs.'
    substituteInPlace "$out/lib/waydroid/data/scripts/"{waydroid-net,waydroid-post-stop}.sh \
      --replace-fail '#!/bin/sh' '#!${runtimeShell}'
    wrapProgram "$out/bin/waydroid-nvidia-setup" --prefix PATH : "$out/bin:${lib.makeBinPath runtimeTools}"
  '';
  preFixup = ''
    makeWrapperArgs+=(--prefix PATH : ${lib.makeBinPath runtimeTools})
  '' + old.preFixup;
  postFixup = ''
    cmp "$out/lib/waydroid/tools/helpers/nvidia_native.py" \
      "$out/lib/waydroid-nvidia/native/waydroid/nvidia_native.py"
  '';
  passthru = { inherit runtimeTools; };
  meta = old.meta // {
    description = "Waydroid with the Android 17 NVIDIA host integration";
    platforms = [ "x86_64-linux" ];
  };
})
