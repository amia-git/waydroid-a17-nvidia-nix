> Translated from Chinese.

# KernelSU as a host DKMS module

Waydroid shares the host kernel. KernelSU requires a compatible host kernel module from supechicken’s `waydroid-experimental` branch. Android init runs `/data/adb/ksud` when the container starts.

The kernel module accepts one manager signing certificate. The official KernelSU manager versionCode does not match this branch. Build and sign your own manager, then compile the certificate length and SHA-256 into the module. Use the certificate values printed in step 3 when building your host module.

Run the manager build commands from the repository root with Podman installed.

## 1. Management source code

```bash
mkdir -p ksu
cp kernelsu/manager/* ksu/
git clone -b waydroid-experimental https://github.com/supechicken/KernelSU ksu/KernelSU
git -C ksu/KernelSU checkout b42ad45981ede55fa84ccdf102956349812e31a5
```

The manager ' s versionCode is `30000 + git rev-list --count HEAD` (this submission is 32708), which must be consistent with the version at the time the module is compiled. If you change the pinned commit, update the expected version in `sign-manager.sh` and use the same source revision for the host module.

## 2. Generate your own signature key

```bash
mkdir -p ksu/keystore && chmod 700 ksu/keystore
cat > ksu/keystore/README <<'EOF'
KEYSTORE_FILE=/work/keystore/ksu-local.jks
KEY_ALIAS=ksu-local
KEYSTORE_PASSWORD=CHOOSE_A_PASSWORD
KEY_PASSWORD=CHOOSE_A_PASSWORD
EOF
chmod 600 ksu/keystore/README
podman build -t localhost/ksu-manager-build -f ksu/Containerfile ksu
podman run --rm -v "$PWD/ksu:/work" localhost/ksu-manager-build bash /work/generate-key.sh
```

`ksu/keystore/` That's your root manager's private key, don't submit it, don't make it public.

## 3. Compiling and signing manager

```bash
podman run --rm -v "$PWD/ksu:/work" -v ksu-gradle-cache:/root/.gradle \
  -v ksu-cargo-cache:/root/.cargo/registry -v ksu-cargo-git:/root/.cargo/git \
  localhost/ksu-manager-build bash /work/build-manager.sh
podman run --rm -v "$PWD/ksu:/work" localhost/ksu-manager-build bash /work/sign-manager.sh
python3 ksu/apk_certificate.py ksu/out/KernelSU_*_32708-local.apk
```

The final command prints `KSU_EXPECTED_SIZE` and `KSU_EXPECTED_HASH`. Sign with APK Signature Scheme v2 only. The kernel module does not accept v3 or other signature blocks.

## 4. Configure the host module

This flake does not package the KernelSU kernel module. Before proceeding, provide a compatible module for your NixOS kernel using the source revision and certificate values above. Configure NixOS to load it before Waydroid starts.

## 5. Installation of Android

`ksud` Already in manager APK (`lib/x86_64/libksud.so`):

```bash
unzip -p ksu/out/KernelSU_*_32708-local.apk lib/x86_64/libksud.so > /tmp/ksud
sudo install -D -m 755 -o root -g root /tmp/ksud ~/.local/share/waydroid/data/adb/ksud
sudo waydroid shell -- /data/adb/ksud install
waydroid app install ksu/out/KernelSU_*_32708-local.apk
waydroid session stop   # Start session again
```

The manager 's front page should show the Working(LKM) page. Clears Waydroid's data and then redos step 5.
