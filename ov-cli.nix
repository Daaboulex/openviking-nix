# ov — Rust CLI client for OpenViking
# Built from the workspace at crates/ov_cli/ using the root Cargo.lock
{
  lib,
  rustPlatform,
  src,
  version,
  pkg-config,
}:

rustPlatform.buildRustPackage {
  pname = "ov-cli";
  inherit version src;

  # TODO: replace with real hash after first build attempt
  cargoHash = lib.fakeHash;

  # Build only the ov_cli crate from the Cargo workspace
  cargoBuildFlags = [ "-p" "ov_cli" ];

  nativeBuildInputs = [ pkg-config ];

  # reqwest uses rustls-tls (not openssl), so no system TLS deps needed

  # Tests require a running OpenViking server
  doCheck = false;

  meta = {
    description = "OpenViking CLI client";
    license = lib.licenses.mit;
    mainProgram = "ov";
    platforms = lib.platforms.linux;
  };
}
