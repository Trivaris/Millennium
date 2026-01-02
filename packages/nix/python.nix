{ 
  pkgsi686Linux,
  autoPatchelfHook,
  ...
}:
pkgsi686Linux.stdenv.mkDerivation(finalAttrs: {
  pname = "millennium-python";
  version = "3.11.8";

  src = builtins.fetchTarball {
    url = "https://www.python.org/ftp/python/3.11.8/Python-3.11.8.tgz";
    sha256 = "sha256:038hnbw3w2ryy0zs94dd1i5zmlqicws7371z3v57c0g3g00lpfrw";
  };

  buildInputs = builtins.attrValues {
    inherit (pkgsi686Linux)
      libxcrypt
      zlib
      openssl
      libffi
      expat
      xz
      bzip2
      ncurses
      gdbm
      sqlite
      util-linux;
  };

  nativeBuildInputs = [
    pkgsi686Linux.pkg-config
    autoPatchelfHook 
  ];

  configurePhase = ''
    runHook preConfigure

    ./configure \
      --prefix=$out \
      --enable-optimizations \
      --without-ensurepip
  
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    make -j$(nproc)

    mkdir -p lib_tmp
    cd lib_tmp

    ar -x ../libpython3.11.a

    gcc -shared -o ../libpython-3.11.8.so *.o -lm -lpthread -lutil -ldl

    cd ..
    rm -rf lib_tmp

    runHook postBuild
  '';

  installPhase = ''
    make altinstall

    cp libpython-3.11.8.so $out/lib/

    rm -rf $out/lib/python3.11/test/
    rm -rf $out/lib/python3.11/__pycache__/
    rm -rf $out/lib/python3.11/config-3.11-*
    rm -rf $out/lib/python3.11/tkinter/
    rm -rf $out/lib/python3.11/idlelib/
    rm -rf $out/lib/python3.11/turtledemo/
    rm -f  $out/lib/libpython3.11.a

    strip $out/bin/python3.11
    strip $out/lib/libpython-3.11.8.so

    rm -f $out/bin/python3.11-config
    rm -f $out/bin/idle3.11
    rm -f $out/bin/pydoc3.11
    rm -f $out/bin/pip3.11
    rm -f $out/bin/2to3-3.11
  '';
})