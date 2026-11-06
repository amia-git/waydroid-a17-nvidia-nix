{ config, lib, pkgs, ... }:
let
  cfg = config.virtualisation.waydroid-a17-nvidia-nix;
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
    systemd.services.waydroid-container.path = package.runtimeTools;
    boot.kernelModules = [ "erofs" ];
  };
}
