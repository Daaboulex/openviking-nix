# ov — Rust CLI client for OpenViking
# Builds the `ov_cli` crate from the workspace at crates/ov_cli/, using the
# shared workspace Cargo vendor (cargoDeps) passed in from flake.nix.
{
  lib,
  rustPlatform,
  src,
  version,
  cargoDeps,
  pkg-config,
}:

rustPlatform.buildRustPackage {
  pname = "ov-cli";
  inherit version src cargoDeps;

  # Build only the ov_cli crate from the Cargo workspace.
  cargoBuildFlags = [
    "-p"
    "ov_cli"
  ];

  nativeBuildInputs = [ pkg-config ];

  # reqwest uses rustls-tls (not openssl), so no system TLS deps needed.

  # Tests require a running OpenViking server.
  doCheck = false;

  meta = {
    description = "OpenViking CLI client";
    homepage = "https://github.com/volcengine/OpenViking";
    license = lib.licenses.asl20;
    mainProgram = "ov";
    platforms = lib.platforms.linux;
  };
}
