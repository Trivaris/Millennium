{
  stdenv,
  pkgsi686Linux,
  self,
  millennium-core,
  millennium-loader,
  inputs,
  cmake,
  ninja,
  openssl,
  git,
  perl,
  python3,
  gcc_multi,
  pkg-config,
  xorg,
  ...
}:
let
  python-32bit = pkgsi686Linux.python3;
  pythonLibName = "libpython${python-32bit.pythonVersion}.so";
  pythonLibPath = "${python-32bit}/lib/${pythonLibName}";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "millennium";
  version = "2.32.0";

  src = self;

  dontUseCmakeConfigure = true;

  nativeBuildInputs = [
    cmake
    ninja
    gcc_multi
    pkg-config
    python3
    git
    perl
  ];

  buildInputs = [
    pkgsi686Linux.openssl
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
    pkgsi686Linux.glibc
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

    # Fix Python linking
    grep -rl "/opt/python-i686-3.11.8" . | xargs sed -i "s|/opt/python-i686-3.11.8|${python-32bit}|g"
    grep -rl "libpython-3.11.8.so" . | xargs sed -i "s|libpython-3.11.8.so|${pythonLibName}|g"

    # Add missing git macros since we simulate the git repo
    cat > scripts/cmake/millennium_version.cmake <<EOF
    set(MILLENNIUM_VERSION "${finalAttrs.version}")
    set(GIT_COMMIT_HASH "nix-build")
    set(MILLENNIUM_VERSION_TAG "v${finalAttrs.version}")

    add_compile_definitions(MILLENNIUM_VERSION="${finalAttrs.version}")
    add_compile_definitions(GIT_COMMIT_HASH="nix-build")
    add_compile_definitions(MILLENNIUM_ROOT="${placeholder "out"}/lib/millennium")
    EOF

    DEPS_DIR=$(pwd)/deps

    FLAGS=$(echo ${
      toString [

        # Override dependencies to use the copies of flake inputs instead of fetching
        "-DFETCHCONTENT_TRY_FIND_PACKAGE_MODE=NEVER"
        "-DFETCHCONTENT_SOURCE_DIR_ZLIB=$DEPS_DIR/zlib"
        "-DFETCHCONTENT_SOURCE_DIR_LUAJIT=$DEPS_DIR/luajit"
        "-DFETCHCONTENT_SOURCE_DIR_LUA_CJSON=$DEPS_DIR/luajson"
        "-DFETCHCONTENT_SOURCE_DIR_MINHOOK=$DEPS_DIR/minhook"
        "-DFETCHCONTENT_SOURCE_DIR_MINI=$DEPS_DIR/mini"
        "-DFETCHCONTENT_SOURCE_DIR_WEBSOCKETPP=$DEPS_DIR/websocketpp"
        "-DFETCHCONTENT_SOURCE_DIR_FMT=$DEPS_DIR/fmt"
        "-DFETCHCONTENT_SOURCE_DIR_NLOHMANN_JSON=$DEPS_DIR/json"
        "-DFETCHCONTENT_SOURCE_DIR_LIBGIT2=$DEPS_DIR/libgit2"
        "-DFETCHCONTENT_SOURCE_DIR_MINIZIP_NG=$DEPS_DIR/minizip"
        "-DFETCHCONTENT_SOURCE_DIR_CURL=$DEPS_DIR/curl"
        "-DFETCHCONTENT_SOURCE_DIR_INCBIN=$DEPS_DIR/incbin"
        "-DFETCHCONTENT_SOURCE_DIR_ASIO=$DEPS_DIR/asio"
        "-DFETCHCONTENT_SOURCE_DIR_RE2=$DEPS_DIR/re2"
        "-DFETCHCONTENT_SOURCE_DIR_ABSEIL=$DEPS_DIR/abseil"

        # Apply Python link fix
        "-DPYTHON_LIBRARY=${pythonLibPath}"
        "-DPYTHON_INCLUDE_DIR=${python-32bit}/include/python${python-32bit.pythonVersion}"

        # Other build flags to fix issues
        "-DBUILD_CLAR=OFF"
        "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
      ]
    })

    substituteInPlace CMakeLists.txt \
      --replace 'DCMAKE_SHARED_LINKER_FLAGS_RELEASE=''${CMAKE_SHARED_LINKER_FLAGS_RELEASE}' \
                "DCMAKE_SHARED_LINKER_FLAGS_RELEASE=''${CMAKE_SHARED_LINKER_FLAGS_RELEASE} $FLAGS'"
  '';

  buildPhase = ''
    runHook preBuild

    # Copy shims and build from our millennium-core and millennium-loader packages
    mkdir -p src/sdk/packages/loader/build
    mkdir -p build
    cp -r ${millennium-loader}/share/millennium/shims/* src/sdk/packages/loader/build/
    cp -r ${millennium-core}/share/millennium/build/* ./build/
    # Ran into problems with git, so create a dummy repo
    git init
    git config user.email "nix-build@localhost"
    git config user.name "Nix Build"
    git add .
    git commit -m "Dummy commit for build"

    cmake --preset linux-release \
          -G "Ninja"

    cmake --build build --config Release

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/millennium
    mkdir -p $out/share/millennium/shims
    mkdir -p $out/share/millennium/assets
    mkdir -p $out/share/licenses/millennium

    install -Dm755 build/src/millennium_x86-build/libmillennium_x86.so                      "$out/lib/millennium/"
    install -Dm755 build/src/millennium_x86-build/boot/linux/libmillennium_bootstrap_86x.so "$out/lib/millennium/"
    install -Dm755 build/src/hhx64-build/libmillennium_hhx64.so                             "$out/lib/millennium/"
    cp -r          src/pipx                                                                 "$out/share/millennium/assets/"
    cp -r          src/sdk/packages/loader/build/*                                          "$out/share/millennium/shims/"
    install -Dm644 LICENSE.md                                                               "$out/share/licenses/millennium/"

    runHook postInstall
  '';
})
