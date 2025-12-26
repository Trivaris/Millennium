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
  pname = "millennium-sdk";
  version = "0.0.0";

  src = self;

  nativeBuildInputs = [ 
    nodejs
    pnpm_9.configHook
  ];

  pnpmRoot = "src/sdk";
  pnpmWorkspaces = [ "@steambrew/api" ];

  pnpmDeps = pnpm_9.fetchDeps {
    inherit (finalAttrs) version pname pnpmWorkspaces;
    src = "${finalAttrs.src}/src/sdk";
    fetcherVersion = 3;
    hash = "sha256-NGq5c1E8yM1hwHvVmjtTnReVrXSxb+AK1Qv4K0FsNDg=";
  };

  buildPhase = ''
    runHook preBuild

    cd src/sdk
    mkdir -p ./scripts
    cp tsconfig.base.json ./scripts

    pnpm --filter=@steambrew/api build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/millennium/shims
    cp -r packages/loader/build/* $out/share/millennium/shims

    runHook postInstall
  '';

})