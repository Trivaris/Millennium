{
  pkgs ? import <nixpkgs>,
}:
let
  inherit (pkgs)
    mkShell
    stdenv_32bit
    nixd
    nixfmt-rfc-style
    mypy
    ;
in
mkShell {
  name = "Millennium";
  stdenv = stdenv_32bit;

  packages = [
    nixd
    nixfmt-rfc-style
    mypy
  ];
}
