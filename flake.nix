# Special thanks to @Sk7Str1p3, @mourogurt, @kaeeraa, @mctrxw for help with this flake and packages
{
  description = ''
    Millennium - an open-source low-code modding framework to create,
    manage and use themes/plugins for the desktop Steam Client
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    websocketpp = {
      url = "github:zaphoyd/websocketpp?ref=1b11fd301531e6df35a6107c1e8665b1e77a2d8e";
      flake = false;
    };
    asio = {
      url = "github:chriskohlhoff/asio?ref=54e3a844eb5f31d25416de9e509d9c24fa203c32";
      flake = false;
    };
    nlohmann = {
      url = "github:nlohmann/json?ref=960b763ecd144f156d05ec61f577b04107290137";
      flake = false;
    };
    fmt = {
      url = "github:fmtlib/fmt?ref=447c6cbf444a99acca078fe30f6f07b2a93868dc";
      flake = false;
    };
    vcpkg = {
      url = "github:microsoft/vcpkg?ref=344525f74edb4c1d47c559d8bbe06240271441d8";
      flake = false;
    };
    crow = {
      url = "github:CrowCpp/Crow?ref=fed82a3aaca93f909b885770036df661305315b6";
      flake = false;
    };
    ini = {
      url = "github:metayeti/mINI?ref=555ee483e0895fa351b7dec59dcb88d8aba2a09f";
      flake = false;
    };
    sdk = {
      url = "github:SteamClientHomebrew/SDK?ref=b0f17cac578205058f8bc3e69ad6d953fea9cd28";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      self,
      websocketpp,
      asio,
      nlohmann,
      fmt,
      vcpkg,
      crow,
      ini,
      sdk,
      ...
    }:
    let
      inherit (self.legacyPackages.${system}) millennium;
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      overlays.default = final: prev: {
        inherit millennium;
        steam-millennium = final.steam.override (prev: {
          extraProfile = ''
            export LD_LIBRARY_PATH="${millennium}/lib/millenium/''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            export LD_PRELOAD="${millennium}/lib/millennium/libmillennium_x86.so''${LD_PRELOAD:+:$LD_PRELOAD}"
          ''
          + (prev.extraProfile or "");
        });

        # Disable flaky watchdog tests globally to avoid sandbox FD limits
        # affecting unrelated builds (e.g., during system rebuilds).
        python3Packages = prev.python3Packages // {
          watchdog = prev.python3Packages.watchdog.overrideAttrs (_: {
            doCheck = false;
            pytestFlagsArray = [
              "-k"
              "not test_select_fd"
            ];
          });
          websockets = prev.python3Packages.websockets.overrideAttrs (_: {
            doCheck = false;
          });
        };
        python311Packages = prev.python311Packages // {
          watchdog = prev.python311Packages.watchdog.overrideAttrs (_: {
            doCheck = false;
            pytestFlagsArray = [
              "-k"
              "not test_select_fd"
            ];
          });
          websockets = prev.python311Packages.websockets.overrideAttrs (_: {
            doCheck = false;
          });
        };
      };

      devShells.${system}.default = import ./shell.nix { inherit pkgs; };

      legacyPackages.${system} = {
        default = self.legacyPackages.${system}.millennium;
        shims = pkgs.callPackage ./nix/typescript/shims.nix { inherit sdk; };
        assets = pkgs.callPackage ./nix/assets.nix { };

        millennium = pkgs.callPackage ./nix/millennium.nix {
          inherit
            websocketpp
            asio
            nlohmann
            fmt
            vcpkg
            crow
            ini
            sdk
            ;
        };

        python = {
          millennium = pkgs.callPackage ./nix/python/millennium.nix { inherit sdk; };
          core-utils = pkgs.callPackage ./nix/python/core-utils.nix { inherit sdk; };
        };
      };
    };
}
