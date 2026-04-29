{ lib
, stdenv
, zig_0_15
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "neonfetch";
  version = "0.0.1";

  src = lib.cleanSource ../.;

  nativeBuildInputs = [ zig_0_15 ];

  dontConfigure = true;

  preBuild = ''
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
  '';

  buildPhase = ''
    runHook preBuild
    zig build -Doptimize=ReleaseFast --prefix "$out"
    runHook postBuild
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    zig build test
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    runHook postInstall
  '';

  meta = {
    description = "Fast synthwave system information fetcher written in Zig";
    homepage = "https://github.com/OpenStaticFish/neonfetch";
    license = lib.licenses.mit;
    mainProgram = "neonfetch";
    platforms = lib.platforms.linux;
  };
})
