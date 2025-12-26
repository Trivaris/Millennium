{
  stdenv,
  ...
}:
let 
  frontend = {
    pname = "millennium-frontend";
    version = "0.0.0";
  };
in stdenv.mkDerivation frontend