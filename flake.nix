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

      version = "0.2.10";

      mkSrc =
        pkgs:
        pkgs.fetchFromGitHub {
          owner = "volcengine";
          repo = "OpenViking";
          rev = "v${version}";
          hash = "sha256-BDe48CvXGRvBGTx3PLYZi6ugVhgGa/vdZZoErnQtUb8=";
        };
    in
    {
      packages = forAllSystems (
        { pkgs, ... }:
        let
          src = mkSrc pkgs;
        in
        rec {
          default = openviking;

          agfs = pkgs.callPackage ./agfs.nix { inherit src version; };
          ov-cli = pkgs.callPackage ./ov-cli.nix { inherit src version; };
          openviking = pkgs.callPackage ./package.nix {
            inherit
              src
              version
              agfs
              ov-cli
              ;
          };
        }
      );

      nixosModules.default = import ./module.nix self;

      overlays.default = final: prev: {
        inherit (self.packages.${final.stdenv.hostPlatform.system})
          openviking
          agfs
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
