{
  stdenv,
  pkgsi686Linux,
  self,
  inputs,
  millennium-shims,
  millennium-assets,
  autoPatchelfHook,
  cmake,
  ninja,
  openssl,
  git,
  perl,
  gcc_multi,
  pkg-config,
  xorg,
  zlib,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "millennium";
  version = "2.32.0";

  src = self;

  nativeBuildInputs = [
    autoPatchelfHook
    cmake
    ninja
    gcc_multi
    pkg-config
    git
    perl
  ];

  buildInputs = [
    pkgsi686Linux.git
    pkgsi686Linux.openssl
    pkgsi686Linux.glibc
    pkgsi686Linux.gtk3
    pkgsi686Linux.zlib-ng
    pkgsi686Linux.libxcrypt

    pkgsi686Linux.xorg.libX11
    pkgsi686Linux.xorg.libXtst
    pkgsi686Linux.xorg.libXi
    pkgsi686Linux.xorg.libXext
    pkgsi686Linux.xorg.libXfixes
    pkgsi686Linux.xorg.libXrender
    pkgsi686Linux.xorg.libXrandr
    pkgsi686Linux.xorg.libXcursor
    pkgsi686Linux.xorg.libXcomposite
    pkgsi686Linux.xorg.libXdamage
    pkgsi686Linux.xorg.libXinerama
    pkgsi686Linux.xorg.libSM
    pkgsi686Linux.xorg.libICE
  ];

  python = pkgsi686Linux.python311;

  cmakeFlags = [
    "-GNinja"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DUSER_CMAKE_MAKE_PROGRAM=ninja"

    "-DDISTRO_NIX=ON"
    "-DNIX_ROOT_PATH=${placeholder "out"}/lib/millennium"
    "-DNIX_MILLENNIUM_PATH_X64=${placeholder "out"}/lib/millennium/libmillennium_hhx64.so"
    "-DNIX_MILLENNIUM_PATH_X86=${placeholder "out"}/lib/millennium/libMillennium_x86.so"
    "-DNIX_ASSETS_PATH=${millennium-assets}/share/millennium/assets"
    "-DNIX_SHIMS_PATH=${millennium-shims}/share/millennium/shims"
    "-DNIX_LIBXTST_PATH=${pkgsi686Linux.xorg.libXtst}/lib/libXtst.so.6"

    "-DNIX_PYTHON_LIB_PREFIX=${finalAttrs.python.libPrefix}"
    "-DNIX_PYTHON_PATH=${finalAttrs.python}"
  ];

  postPatch = ''
    mkdir -p deps

    prepare_dep() {
      local name="$1"
      local src="$2"
      echo "Preparing dependency: $name"
      cp -r --no-preserve=mode "$src" "deps/$name"
      chmod -R u+w "deps/$name"
    }

    # Copy all flake inputs to local writable directory
    prepare_dep zlib        "${inputs.zlib-src}"
    prepare_dep luajit      "${inputs.luajit-src}"
    prepare_dep luajson     "${inputs.luajson-src}"
    prepare_dep minhook     "${inputs.minhook-src}"
    prepare_dep mini        "${inputs.mini-src}"
    prepare_dep websocketpp "${inputs.websocketpp-src}"
    prepare_dep fmt         "${inputs.fmt-src}"
    prepare_dep json        "${inputs.nlohmann-json-src}"
    prepare_dep libgit2     "${inputs.libgit2-src}"
    prepare_dep minizip     "${inputs.minizip-ng-src}"
    prepare_dep curl        "${inputs.curl-src}"
    prepare_dep incbin      "${inputs.incbin-src}"
    prepare_dep asio        "${inputs.asio-src}"
    prepare_dep abseil      "${inputs.abseil-src}"
    prepare_dep re2         "${inputs.re2-src}"
  '';

  configurePhase = ''
    runHook preConfigure

    # Dummy Commits because git is used to determine versions, but flake inputs strip git history
    git init
    git config user.name "Nix Build"
    git config user.email "nix-build@localhost"
    git add . > /dev/null 2>&1
    git commit -m "Dummy commit for build" > /dev/null 2>&1

    git init deps/luajit
    git -C deps/luajit config user.email "nix-build@localhost"
    git -C deps/luajit config user.name "Nix Build"
    git -C deps/luajit checkout -b main
    git -C deps/luajit add . > /dev/null 2>&1
    git -C deps/luajit commit -m "Dummy Commit for Nix Build" > /dev/null 2>&1

    export DEPS_DIR="$(pwd)/deps"
    export CFLAGS="$CFLAGS -I$DEPS_DIR/luajit/src"

    mkdir -p build
    mkdir -p src/sdk/packages/loader/build
    mkdir -p $out/lib/millennium

    cp -L ${finalAttrs.python}/lib/libpython3.11.so.1.0 $out/lib/millennium/libpython3.11.so
    cp -r ${finalAttrs.python}/lib/python3.11 $out/lib/millennium/lib/

    cp -r ${millennium-assets}/share/millennium/assets/* build/
    cp -r ${millennium-shims}/share/millennium/shims/* src/sdk/packages/loader/build

    cmake --preset linux-release $cmakeFlags \
      -DNIX_DEPS_DIR=$DEPS_DIR \
      -DNIX_MILLENNIUM_BASE=$(pwd)

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    cmake --build build --config Release

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/millennium

    install -Dm755 build/src/millennium_x86-build/libmillennium_x86.so $out/lib/millennium/libMillennium_x86.so
    install -Dm755 build/src/millennium_x86-build/boot/linux/libmillennium_bootstrap_86x.so $out/lib/millennium/
    install -Dm755 build/src/hhx64-build/libmillennium_hhx64.so $out/lib/millennium/

    runHook postInstall
  '';

})
