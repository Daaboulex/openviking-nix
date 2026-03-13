{
  description = "OpenViking — agent-native context database for AI agents";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      version = "0.2.7";

      src = pkgs.fetchFromGitHub {
        owner = "volcengine";
        repo = "OpenViking";
        rev = "v${version}";
        hash = "sha256-8VWDJ+hp5p3cWODJdcPvT1PNriZr73pFTiDjY81yT8Q=";
      };
    in
    {
      packages.${system} = rec {
        default = openviking;

        agfs = pkgs.callPackage ./agfs.nix { inherit src version; };
        ov-cli = pkgs.callPackage ./ov-cli.nix { inherit src version; };
        openviking = pkgs.callPackage ./package.nix { inherit src version agfs ov-cli; };
      };

      nixosModules.default = import ./module.nix self;

      overlays.default = final: prev: {
        inherit (self.packages.${final.stdenv.hostPlatform.system})
          openviking
          agfs
          ov-cli
          ;
      };

      formatter.${system} = pkgs.nixfmt-rfc-style;
    };
}
