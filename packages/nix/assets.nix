{
  stdenv,
  nodejs,
  pnpm_9,
  pnpmConfigHook,
  fetchPnpmDeps,
  self,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "millennium-assets";
  version = "0.0.0";

  src = self + "/src";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/millennium/assets/
    cp -r pipx/ $out/share/millennium/assets/

    runHook postInstall
  '';

})