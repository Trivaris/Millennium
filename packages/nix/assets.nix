{
  stdenv,
  nodejs_20,
  pnpm_9,
  unzip,
  fetchPnpmDeps,
  pnpmConfigHook,
  self,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "millennium-assets";
  version = "1.0.0";

  src = self;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/millennium/assets/
    cp -r src/pipx $out/share/millennium/assets/pipx

    runHook postInstall
  '';

})
