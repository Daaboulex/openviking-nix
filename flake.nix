{
  description = "OpenViking - agent-native context database for AI agents";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    std = {
      url = "github:Daaboulex/nix-packaging-standard?ref=v2.11.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.git-hooks.follows = "git-hooks";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      let
        # Temporary nixpkgs fixes (standard convention, "Temporary nixpkgs
        # overlays" in the standard's README): one { meta, dropWhen, overlay }
        # file per fix under overlays/; scripts/heal-overlays.sh (Maintenance)
        # deletes a fix once its dropWhen fires against the un-fixed pkgs.
        fixOverlays =
          let
            dir = ./overlays;
            names = if builtins.pathExists dir then builtins.attrNames (builtins.readDir dir) else [ ];
          in
          map (n: (import (dir + "/${n}")).overlay) (
            builtins.filter (n: inputs.nixpkgs.lib.hasSuffix ".nix" n) names
          );
      in
      {
        systems = [ "x86_64-linux" ];
        imports = [ inputs.std.flakeModules.base ];

        flake = {
          nixosModules.default = import ./module.nix inputs.self;

          overlays = {
            default = final: prev: {
              inherit (inputs.self.packages.${final.stdenv.hostPlatform.system})
                openviking
                ov-cli
                ;
            };
            # No permanent glue overlay here -- fixes apply to this flake's own
            # pkgs below, so the heal probe evaluates plain nixpkgs.
            probe = _final: _prev: { };
          };
        };

        perSystem =
          { pkgs, system, ... }:
          let
            version = "0.4.11";
            # Distinct hash names so the updater (update.json hashes [hash, cargoHash])
            # targets each unambiguously: a bare `hash =` for the source, `cargoHash =`
            # for the vendor. Two same-named `hash =` literals here previously collided
            # and the updater clobbered both with the source hash (issue #6).
            cargoHash = "sha256-mSh/skZkbshVzOaWR8Jef3ngKP7FtWFKKiqw9NNc5XE=";
            src = pkgs.fetchFromGitHub {
              owner = "volcengine";
              repo = "OpenViking";
              rev = "v${version}";
              hash = "sha256-F+qbuBENuaqbxDxQrPzDhbADk1i4O9/L/UbqFDqYVz0=";
            };

            # Shared Cargo vendor for the workspace (crates/{ov_cli,ragfs,ragfs-python}).
            # All three crates resolve against the single root Cargo.lock, so one
            # vendor - and one cargoHash - covers every Rust build in this repo.
            cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
              inherit src;
              hash = cargoHash;
            };

            ov-cli = pkgs.callPackage ./ov-cli.nix { inherit src version cargoDeps; };
            ragfs-python = pkgs.callPackage ./ragfs-python.nix { inherit src version cargoDeps; };
            openviking = pkgs.callPackage ./package.nix {
              inherit
                src
                version
                ov-cli
                ragfs-python
                ;
            };
          in
          {
            # Fixes from overlays/ reach every consumer of this flake's pkgs.
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = fixOverlays;
            };

            packages = {
              default = openviking;
              inherit openviking ov-cli ragfs-python;
            };
          };
      }
    );
}
