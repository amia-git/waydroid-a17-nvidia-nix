{ config, lib, pkgs, ... }:
let
  cfg = config.virtualisation.waydroid-a17-nvidia-nix;
  renderDevice = "sys-subsystem-waydroid_nvidia-render.device";
  package = pkgs.callPackage ./package.nix {
    withNftables = config.networking.nftables.enable;
  };
in
{
  options.virtualisation.waydroid-a17-nvidia-nix.enable =
    lib.mkEnableOption "Waydroid with the Android 17 NVIDIA host integration";

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
      message = "Waydroid A17 NVIDIA requires x86_64 Linux.";
    }];

    virtualisation.waydroid = {
      enable = true;
      inherit package;
    };

    services.udev.packages = [ package ];
    systemd.services.waydroid-container = {
      path = package.runtimeTools;
      wants = [ renderDevice ];
      after = [ renderDevice ];
      preStart = ''
        if [ -f /var/lib/waydroid-nvidia/vendor-image/install.json ]; then
          ${pkgs.python3}/bin/python3 ${package}/lib/waydroid-nvidia/native/dev/driver-mode verify-active
        fi
      '';
    };
    boot.kernelModules = [ "erofs" "xfrm_user" "xfrm_interface" ];
  };
}
