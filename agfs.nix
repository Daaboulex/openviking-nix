# AGFS — Agent File System server + Python binding shared library
# Builds two Go artifacts from third_party/agfs/agfs-server/:
#   1. agfs-server binary (pure Go)
#   2. libagfsbinding.so (CGO c-shared library for Python integration)
{
  lib,
  buildGoModule,
  src,
  version,
}:

buildGoModule {
  pname = "agfs";
  inherit version src;

  # Go module root within the monorepo source tree
  # The go.mod here has: replace github.com/c4pt0r/agfs/agfs-sdk/go => ../agfs-sdk/go
  # This works because fetchSubmodules=true includes the full third_party/agfs/ tree
  modRoot = "third_party/agfs/agfs-server";

  # TODO: replace with real hash after first build attempt
  vendorHash = lib.fakeHash;

  # CGO needed for the binding shared library
  CGO_ENABLED = "1";

  # Custom build: produce both server binary and shared library
  buildPhase = ''
    runHook preBuild

    # Server binary (standard Go binary)
    go build -v -trimpath -o agfs-server ./cmd/server

    # Python binding shared library (CGO, c-shared build mode)
    go build -buildmode=c-shared -v -trimpath -o libagfsbinding.so ./cmd/pybinding

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib
    install -Dm755 agfs-server $out/bin/agfs-server
    install -Dm755 libagfsbinding.so $out/lib/libagfsbinding.so

    runHook postInstall
  '';

  # Tests require running services / network
  doCheck = false;

  meta = {
    description = "AGFS — Agent File System server and Python binding library";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
