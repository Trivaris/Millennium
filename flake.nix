{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    zlib-src = {
      url = "github:zlib-ng/zlib-ng/2.2.5?shallows=true";
      flake = false;
    };

    luajit-src = {
      url = "github:SteamClientHomebrew/LuaJIT/v2.1?shallows=true";
      flake = false;
    };

    luajson-src = {
      url = "github:SteamClientHomebrew/LuaJSON/master?shallows=true";
      flake = false;
    };

    minhook-src = {
      url = "github:TsudaKageyu/minhook/v1.3.4?shallows=true";
      flake = false;
    };

    mini-src = {
      url = "github:metayeti/mINI/0.9.18?shallows=true";
      flake = false;
    };

    websocketpp-src = {
      url = "github:zaphoyd/websocketpp/0.8.2?shallows=true";
      flake = false;
    };

    fmt-src = {
      url = "github:fmtlib/fmt/12.0.0?shallows=true";
      flake = false;
    };

    nlohmann-json-src = {
      url = "github:nlohmann/json/v3.12.0?shallows=true";
      flake = false;
    };

    libgit2-src = {
      url = "github:libgit2/libgit2/v1.9.1?shallows=true";
      flake = false;
    };

    minizip-ng-src = {
      url = "github:zlib-ng/minizip-ng/4.0.10?shallows=true";
      flake = false;
    };

    curl-src = {
      url = "github:curl/curl/curl-8_13_0?shallows=true";
      flake = false;
    };

    incbin-src = {
      url = "github:graphitemaster/incbin/main?shallows=true";
      flake = false;
    };

    asio-src = {
      url = "github:chriskohlhoff/asio/asio-1-30-0?shallows=true";
      flake = false;
    };

    abseil-src = {
      url = "github:abseil/abseil-cpp/20240722.0";
      flake = false;
    };

    re2-src = {
      url = "github:google/re2/2025-11-05";
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

            steam-millennium = pkgs.steam.override {
              extraProfile = ''
                mkdir -p "$HOME/.local/share/Steam/ubuntu12_32"
                rm -rf "$HOME/.local/share/Steam/ubuntu12_32/libXtst.so.6"
                ln -sf ${packages.millennium}/lib/millennium/libmillennium_bootstrap_86x.so "$HOME/.local/share/Steam/ubuntu12_32/libXtst.so.6"
                export NIX_PYTHON_LIB=${packages.millennium.python}/lib/libpython-3.11.8.so
                export LD_SO_SILENT=1
              '';
            };

            millennium = pkgs.callPackage ./packages/nix/millennium.nix { self = ./.; inherit inputs; inherit (packages) millennium-assets millennium-shims millennium-frontend; };
            millennium-python = packages.millennium.python;
            millennium-assets = pkgs.callPackage ./packages/nix/assets.nix { self = ./.; };
            millennium-frontend = pkgs.callPackage ./packages/nix/frontend.nix { self = ./.; };
            millennium-shims = pkgs.callPackage ./packages/nix/shims.nix { self = ./.; };
            millennium-bin = pkgs.callPackage ./packages/nix/millennium-bin.nix { };
          };
        in
        packages
      );

      overlays.default =
        final: prev:
        {
            steam-millennium = prev.steam.override {
              extraProfile = ''
                mkdir -p "$HOME/.local/share/Steam/ubuntu12_32"
                rm -rf "$HOME/.local/share/Steam/ubuntu12_32/libXtst.so.6"
                # ln -sf ${self.packages.${final.system}.millennium}/lib/millennium/libmillennium_bootstrap_86x.so "$HOME/.local/share/Steam/ubuntu12_32/libXtst.so.6"
                ln -sf ${prev.pkgsi686Linux.xorg.libXtst}/lib/libXtst.so.6 "$HOME/.local/share/Steam/ubuntu12_32/libXtst.so.6"
                
                export NIX_PYTHON_LIB=${self.packages.${final.system}.millennium.python}/lib/libpython-3.11.8.so
                export LD_SO_SILENT=1
		            export LD_PRELOAD=${self.packages.${final.system}.millennium}/lib/millennium/libmillennium_hhx64.so:${self.packages.${final.system}.millennium}/lib/millennium/libmillennium_x86.so"
              '';
            };
        };
    };
}
