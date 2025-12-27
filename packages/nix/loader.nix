{
  stdenv,
  nodejs_20,
  pnpm_9,
  pnpmConfigHook,
  fetchPnpmDeps,
  self,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "millennium-loader";
  version = "0.0.0";

  src = self;

  nativeBuildInputs = [ 
    nodejs_20
    pnpm_9
    pnpmConfigHook
  ];

  pnpmRoot = "src/sdk";
  pnpmWorkspaces = [ "@steambrew/api" ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) version pname pnpmWorkspaces;
    src = "${finalAttrs.src}/src/sdk";
    fetcherVersion = 3;
    hash = "sha256-YaOHf5pfStiOG/ay3QKTAyIfjH39hVRnw53qucNeJG8=";
  };

  buildPhase = ''
    runHook preBuild

    mkdir -p src/sdk/scripts
    cp src/sdk/tsconfig.base.json src/sdk/scripts

    pnpm --dir src/sdk --filter=@steambrew/api build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/millennium/shims
    cp -r src/sdk/packages/loader/build/* $out/share/millennium/shims

    runHook postInstall
  '';

})