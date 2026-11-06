{
  description = "Android 17 Waydroid with NVIDIA acceleration on NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }: {
    nixosModules.default = import ./nix/module.nix;
    packages.x86_64-linux = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in rec {
      waydroid-a17-nvidia-nix = pkgs.callPackage ./nix/package.nix { };
      default = waydroid-a17-nvidia-nix;
    };
    checks.x86_64-linux = let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      package = self.packages.${system}.default;
      moduleConfig = enable: (nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          self.nixosModules.default
          {
            system.stateVersion = "26.05";
            networking.nftables.enable = true;
            virtualisation.waydroid-a17-nvidia-nix.enable = enable;
          }
        ];
      }).config;
      enabled = moduleConfig true;
      container = enabled.systemd.services.waydroid-container;
    in {
      nixos-module =
        assert !(moduleConfig false).virtualisation.waydroid.enable;
        assert enabled.virtualisation.waydroid.enable;
        assert enabled.virtualisation.waydroid.package.drvPath == package.drvPath;
        assert builtins.all (name: builtins.elem name enabled.boot.kernelModules)
          [ "erofs" "xfrm_user" "xfrm_interface" ];
        assert builtins.elem "sys-subsystem-waydroid_nvidia-render.device" container.after;
        pkgs.runCommand "waydroid-nixos-module-check" { } "touch $out";

      package-smoke = pkgs.runCommand "waydroid-package-smoke" { } ''
        ${package}/bin/waydroid --version
        test -x ${package}/bin/waydroid-nvidia-setup
        test -f ${package}/lib/udev/rules.d/70-waydroid-nvidia-gpu.rules
        touch "$out"
      '';
    };
  };
}
