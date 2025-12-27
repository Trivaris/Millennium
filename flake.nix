{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    zlib-src = {
      url = "github:zlib-ng/zlib-ng?ref=6d9f3dc072369dc719a5fbe71d4e086a96a680bd"; # 2.3.2 Commit
      flake = false;
    };

    luajit-src = {
      url = "github:SteamClientHomebrew/LuaJIT?ref=89550023569c3e195e75e12951c067fe5591e0d2"; # Latest Commit as of 2025-12-27
      flake = false;
    };

    luajson-src = {
      url = "github:SteamClientHomebrew/LuaJSON?ref=0c1fabf07c42f3907287d1e4f729e0620c1fe6fd"; # Latest Commit as of 2025-12-27
      flake = false;
    };

    minhook-src = {
      url = "github:TsudaKageyu/minhook?ref=c3fcafdc10146beb5919319d0683e44e3c30d537"; # v1.3.4 Commit
      flake = false;
    };

    mini-src = {
      url = "github:metayeti/mINI?ref=52b66e987cb56171dc91d96115cdf094b6e4d7a0"; # 0.9.18 Commit
      flake = false;
    };

    websocketpp-src = {
      url = "github:zaphoyd/websocketpp?ref=56123c87598f8b1dd471be83ca841ceae07f95ba"; # 0.8.2 Commit
      flake = false;
    };

    fmt-src = {
      url = "github:fmtlib/fmt?ref=e424e3f2e607da02742f73db84873b8084fc714c"; # 12.0.0 Commit
      flake = false;
    };

    nlohmann-json-src = {
      url = "github:nlohmann/json?ref=55f93686c01528224f448c19128836e7df245f72"; # 3.12.0 Commit
      flake = false;
    };

    libgit2-src = {
      url = "github:libgit2/libgit2?ref=0060d9cf5666f015b1067129bd874c6cc4c9c7ac"; # v1.9.1 Commit
      flake = false;
    };

    minizip-ng-src = {
      url = "github:zlib-ng/minizip-ng?ref=f3ed731e27a97e30dffe076ed5e0537daae5c1bd"; # 4.0.10 Commit
      flake = false;
    };

    curl-src = {
      url = "github:curl/curl?ref=1c3149881769e7bd79b072e48374e4c2b3678b2f"; # 8.13.0 Commit
      flake = false;
    };

    incbin-src = {
      url = "github:graphitemaster/incbin?ref=22061f51fe9f2f35f061f85c2b217b55dd75310d"; # Latest Commit as of 2025-12-27
      flake = false;
    };

    asio-src = {
      url = "github:chriskohlhoff/asio?ref=22ccfc94fc77356f7820601f9f33b9129a337d2d"; # 1.30.0 Commit
      flake = false;
    };

    abseil-src = {
      url = "github:abseil/abseil-cpp?ref=4447c7562e3bc702ade25105912dce503f0c4010"; # 20240722.0 Commit
      flake = false;
    };

    re2-src = {
      url = "github:google/re2?ref=927f5d53caf8111721e734cf24724686bb745f55"; # 2025-11-05 Commit
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      systems = [ "x86_64-linux" ];
      forEachSystem =
        f:
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = f (
              import nixpkgs {
                inherit system;
                config = {
                  allowUnfree = true;
                };
              }
            );
          }) systems
        );
    in
    {
      packages = forEachSystem (
        pkgs:
        let
          packages = {
            default = packages.millennium;
            millennium-core = pkgs.callPackage ./packages/nix/core.nix { self = ./.; };
            millennium-loader = pkgs.callPackage ./packages/nix/loader.nix { self = ./.; };
            millennium-bin = pkgs.callPackage ./packages/nix/millennium-bin.nix { };
            millennium = pkgs.callPackage ./packages/nix/millennium.nix {
              inherit inputs;
              inherit (packages) millennium-core millennium-loader;
              self = ./.;
            };
          };
        in
        packages
      );

      overlays.default =
        final: prev:
        let 
          millennium = self.packages.${prev.system}.millennium;
          millennium-bin = self.packages.${prev.system}.millennium-bin;
        in 
        {
          steam-millennium = prev.steam.override {
            extraPkgs = pkgs: [
              millennium
              pkgs.pkgsi686Linux.openssl
            ];

            extraArgs = "-loader ${millennium}/lib/millennium/libmillennium_x86.so";

            extraProfile = ''
              mkdir -p "$HOME/.local/share/Steam/ubuntu12_32"
              ln -sf ${millennium}/lib/millennium/libmillennium_bootstrap_86x.so \
                "$HOME/.local/share/Steam/ubuntu12_32/libXtst.so.6"

              mkdir -p "$HOME/.steam/steam"
              touch "$HOME/.steam/steam/.cef-enable-remote-debugging"

              export OPENSSL_CONF=/dev/null
              export MILLENNIUM_DISABLE_WEBHELPER_HOOK=1

              unset LD_PRELOAD
              unset PYTHONHOME
              unset PYTHONPATH
            '';
          };
        };
    };
}
