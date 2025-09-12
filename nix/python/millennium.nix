{ pkgs, sdk }:
pkgs.python311Packages.buildPythonPackage {
  pname = "millennium";
  version = "git";

  src = sdk + "/python-packages/millennium";
  pyproject = true;
  build-system = [ pkgs.python311Packages.setuptools ];
  postPatch = ''
    substituteInPlace setup.py \
      --replace "../../package.json" "./package.json" \
      --replace "../../README.md" "./README.md"
  '';
  preBuild = ''
    cp ${sdk}/package.json ./package.json
    cp ${sdk}/README.md ./README.md
  '';
}
