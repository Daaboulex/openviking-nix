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
      url = "github:Daaboulex/nix-packaging-standard?ref=v2.7.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.git-hooks.follows = "git-hooks";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ inputs.std.flakeModules.base ];

      flake = {
        nixosModules.default = import ./module.nix inputs.self;

        overlays.default = final: prev: {
          inherit (inputs.self.packages.${final.stdenv.hostPlatform.system})
            openviking
            ov-cli
            ;
        };
      };

      perSystem =
        { pkgs, ... }:
        let
          version = "0.3.24";
          src = pkgs.fetchFromGitHub {
            owner = "volcengine";
            repo = "OpenViking";
            rev = "v${version}";
            hash = "sha256-8yIaUe2UKe/lek0QmBQNm6fv9UjL97MmQ8OA+/YQEqM=";
          };

          # Shared Cargo vendor for the workspace (crates/{ov_cli,ragfs,ragfs-python}).
          # All three crates resolve against the single root Cargo.lock, so one
          # vendor - and one cargoHash - covers every Rust build in this repo.
          cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
            inherit src;
            hash = "sha256-1fd6wMzmEWi6cfOcrpYVN9MMHHF8Fan8e3Z+ubZV7Lw=";
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
          packages = {
            default = openviking;
            inherit openviking ov-cli ragfs-python;
          };
        };
    };
}
