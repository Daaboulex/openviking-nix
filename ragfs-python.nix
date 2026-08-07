# ragfs-python — PyO3 Python bindings for RAGFS (the Rust AGFS rewrite).
# Builds the crates/ragfs-python cdylib via maturin into an abi3 extension
# module (ragfs_python.abi3.so). Replaces the old CGO libagfsbinding.so.
# Uses the shared workspace Cargo vendor (cargoDeps) from flake.nix.
{
  lib,
  python3Packages,
  rustPlatform,
  rustc,
  cargo,
  pkg-config,
  src,
  cargoDeps,
}:

python3Packages.buildPythonPackage {
  pname = "ragfs-python";
  # The crate versions itself independently of the OpenViking release; nixpkgs'
  # pythonMetadataCheckPhase compares this against the built wheel's METADATA,
  # so an upstream crate bump fails loudly here instead of shipping a lie.
  version = "0.1.0";
  inherit src cargoDeps;
  pyproject = true;

  # The maturin project lives in the workspace subdirectory.
  buildAndTestSubdir = "crates/ragfs-python";

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
    rustc
    cargo
    pkg-config
  ];

  # ragfs (a path dependency) bundles SQLite via rusqlite's `bundled`
  # feature and uses rustls for S3 — no system TLS/sqlite libraries needed.

  # Tests need a running filesystem backend.
  doCheck = false;

  # No import check here: the crate's #[pymodule] init hard-imports
  # openviking.storage.errors, and openviking depends on this package, so the
  # extension is only importable from openviking's environment. The check lives
  # there (package.nix pythonImportsCheck).

  meta = {
    description = "PyO3 Python bindings for RAGFS — the Rust AGFS filesystem";
    homepage = "https://github.com/volcengine/OpenViking";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
