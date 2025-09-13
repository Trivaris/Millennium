{
  pkgsi686Linux,
  cmake,
  ninja,
  callPackage,
  lib,
  websocketpp,
  asio,
  nlohmann,
  fmt,
  vcpkg,
  crow,
  ini,
  sdk,
}:
let
  pkgs = pkgsi686Linux;
  shims = callPackage ./typescript/shims.nix { inherit sdk; };
  assets = callPackage ./assets.nix { };

  venv = pkgs.python311.withPackages (
    py:
    let
      # The watchdog test suite tries to exhaust >1024 fds which
      # fails under typical sandbox ulimit. Disable the flaky test run.
      watchdogNoCheck = py.watchdog.overridePythonAttrs (_: {
        doCheck = false;
        # As an extra guard, if checks are ever re-enabled upstream:
        pytestFlagsArray = [
          "-k"
          "not test_select_fd"
        ];
      });
    in
    (builtins.attrValues {
      inherit (py)
        setuptools
        pip
        arrow
        psutil
        requests
        gitpython
        cssutils
        websockets
        pysocks
        pyperclip
        semver
        ;
    })
    ++ [
      watchdogNoCheck
      (callPackage ./python/millennium.nix {
        inherit sdk pkgs;
      })
      (callPackage ./python/core-utils.nix {
        inherit sdk pkgs;
      })
    ]
  );
in
pkgs.stdenv.mkDerivation {
  pname = "millennium";
  version = "git";
  src = ../.;

  pyproject = true;
  build-system = [ pkgs.python311Packages.setuptools ];

  buildInputs = [
    shims
    assets
    pkgs.python311
    (pkgs.openssl.override { static = true; })
    (
      (pkgs.curl.override {
        http2Support = false;
        gssSupport = false;
        zlibSupport = true;
        opensslSupport = true;
        brotliSupport = false;
        zstdSupport = false;
        http3Support = false;
        scpSupport = false;
        pslSupport = false;
        idnSupport = false;
      }).overrideAttrs
      (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [
          "--enable-static"
          "--disable-shared"
        ];
        propagatedBuildInputs = [
          (pkgs.openssl.override {
            static = true;
          }).out
        ];
      })
    )
  ];

  nativeBuildInputs = [
    cmake
    ninja
  ];

  env = {
    inherit venv assets shims;
    NIX_OS = 1;
  };

  postPatch = ''
    # Replace git submodules with flake-provided sources by wiring symlinks
    mkdir -p vendor
    rm -rf vendor/websocketpp vendor/asio vendor/nlohmann vendor/fmt vendor/vcpkg vendor/crow vendor/ini sdk || true

    # Copy websocketpp to allow patching for newer Asio APIs
    cp -r ${websocketpp} vendor/websocketpp
    chmod -R u+w vendor/websocketpp || true
    ln -s ${asio}        vendor/asio
    ln -s ${nlohmann}    vendor/nlohmann
    ln -s ${fmt}         vendor/fmt
    ln -s ${vcpkg}       vendor/vcpkg
    ln -s ${crow}        vendor/crow
    ln -s ${ini}         vendor/ini
    ln -s ${sdk}         sdk

    # Patch websocketpp for standalone Asio where expires_from_now was removed
    if [ -f vendor/websocketpp/websocketpp/transport/asio/connection.hpp ]; then
      substituteInPlace vendor/websocketpp/websocketpp/transport/asio/connection.hpp \
        --replace "->expires_from_now()" "->expiry() - std::chrono::steady_clock::now()"
    fi
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/millennium
    cp libmillennium_x86.so $out/lib/millennium

    runHook postInstall
  '';

  NIX_CFLAGS_COMPILE = [
    "-isystem ${pkgs.python311}/include/${pkgs.python311.libPrefix}"
  ];

  NIX_LDFLAGS = [ "-l${pkgs.python311.libPrefix}" ];

  meta = {
    maintainers = [ lib.maintainers.Sk7Str1p3 ];
  };
}
