{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux = let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      in
      {
        loader = pkgs.callPackage ./packages/nix/loader.nix { inherit self; };
        assets = pkgs.callPackage ./packages/nix/assets.nix { inherit self; };
      };
  };
}
