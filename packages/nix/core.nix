{
  stdenv,
  nodejs,
  pnpm_9,
  fetchPnpmDeps,
  pnpmConfigHook,
  self,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "millennium-core";
  version = "0.0.0";

  src = self;

  nativeBuildInputs = [
    nodejs
    pnpm_9
    pnpmConfigHook
  ];

  pnpmRoot = "src/frontend";

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) version pname;
    src = "${finalAttrs.src}/src/frontend";
    fetcherVersion = 3;
    hash = "sha256-i53ZZ8ehOi3ybuckUo1Js5tC4LB0QCe4IQCwDwoegXg=";
  };

  buildPhase = ''
    runHook preBuild

    pnpm --dir src/frontend run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    ls -la

    mkdir -p $out/share/millennium/build
    cp -r build/frontend.bin $out/share/millennium/build

    runHook postInstall
  '';

})
