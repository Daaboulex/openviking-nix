{
  description = "OpenViking — agent-native context database for AI agents";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      git-hooks,
    }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems =
        fn:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          fn {
            pkgs = import nixpkgs { localSystem.system = system; };
            inherit system;
          }
        );

      version = "0.3.22";

      mkSrc =
        pkgs:
        pkgs.fetchFromGitHub {
          owner = "volcengine";
          repo = "OpenViking";
          rev = "v${version}";
          hash = "sha256-AzovVT6Qajjvh1dcwwuqb0XDCs8bjuS5k0r5za54rG0=";
        };

      # Shared Cargo vendor for the workspace (crates/{ov_cli,ragfs,ragfs-python}).
      # All three crates resolve against the single root Cargo.lock, so one
      # vendor — and one cargoHash — covers every Rust build in this repo.
      cargoHash = "sha256-lVVbZPQPq0Hp8QWb6awnTAsa0aiuoBN/culZ3m/jV+4=";
    in
    {
      packages = forAllSystems (
        { pkgs, ... }:
        let
          src = mkSrc pkgs;
          cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
            inherit src;
            hash = cargoHash;
          };
        in
        rec {
          default = openviking;

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
        }
      );

      nixosModules.default = import ./module.nix self;

      overlays.default = final: prev: {
        inherit (self.packages.${final.stdenv.hostPlatform.system})
          openviking
          ov-cli
          ;
      };

      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixfmt);

      checks = forAllSystems (
        { system, ... }:
        {
          pre-commit-check = git-hooks.lib.${system}.run {
            src = self;
            hooks.nixfmt-rfc-style.enable = true;
            hooks.typos.enable = true;
            hooks.rumdl.enable = true;
            hooks.check-readme-sections = {
              enable = true;
              name = "check-readme-sections";
              entry = "bash scripts/check-readme-sections.sh";
              files = "README\.md$";
              language = "system";
            };
          };
        }
      );

      devShells = forAllSystems (
        { pkgs, system }:
        {
          default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
            packages = with pkgs; [ nil ];
          };
        }
      );
    };
}
