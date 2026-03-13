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

  cargoHash = "sha256-4rl0nL+4+LFOQDMdk67wW6pcJ+68/OpxCIqFuoIqhbI=";

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
