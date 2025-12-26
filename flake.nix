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
        sdk = pkgs.callPackage ./packages/nix/sdk.nix { inherit self; };
        frontend = pkgs.callPackage ./packages/nix/frontend.nix { };
      };

  };
}
