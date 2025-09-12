{ lib, cmake, ninja, fetchzip, cross }:
let
  pyWin = fetchzip {
    url = "https://github.com/SteamClientHomebrew/PythonBuildAgent/releases/download/v1.0.9/python-windows.zip";
    hash = "sha256-kWN6kC7lLMxj2tMsNU8NYcQmtiXaspHl3K/e1AFy3Vw=";
    stripRoot = false;
  };
in
cross.stdenv.mkDerivation {
  pname = "millennium-windows";
  version = "git";
  src = ../.;

  nativeBuildInputs = [
    cmake
    ninja
  ];

  buildInputs = [
    (cross.curl.override {
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
    })
    cross.openssl
  ];

  cmakeFlags = [
    "-G" "Ninja"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DGITHUB_ACTION_BUILD=ON"
  ];

  preConfigure = ''
    mkdir -p build/python
    cp -v ${pyWin}/artifacts/windows/python311.lib build/python/python311.lib
    # Debug lib may not always be needed; copy if present
    if [ -f ${pyWin}/artifacts/windows/python311_d.lib ]; then
      cp -v ${pyWin}/artifacts/windows/python311_d.lib build/python/python311_d.lib
    fi
    # DLLs not required for link, but harmless to stage
    cp -v ${pyWin}/artifacts/windows/python311.dll build/python/python311.dll || true
    cp -v ${pyWin}/artifacts/windows/python311_d.dll build/python/python311_d.dll || true
  '';

  env = {
    NIX_OS = 1;
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/millennium

    # Millennium main DLL is placed at top-level of build dir by CMake
    cp -v millennium.dll $out/lib/millennium/

    # Optional: preload shim built on Windows (if enabled by CMake)
    if [ -f preload/user32.dll ]; then
      cp -v preload/user32.dll $out/lib/millennium/
    fi

    runHook postInstall
  '';

  meta = {
    description = "Millennium Windows DLL built via MinGW (cross-compiled)";
    platforms = [ "x86_64-linux" ];
    maintainers = [ lib.maintainers.Trivaris ];
  };
}
