{
  description = "Android 17 Waydroid with NVIDIA acceleration on NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }: {
    nixosModules.default = import ./nix/module.nix;
    packages.x86_64-linux = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in rec {
      waydroid-a17-nvidia = pkgs.callPackage ./nix/package.nix { };
      default = waydroid-a17-nvidia;
    };
  };
}
