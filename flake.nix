{
  description = "OpenViking — agent-native context database for AI agents";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      version = "0.2.7";

      src = pkgs.fetchFromGitHub {
        owner = "volcengine";
        repo = "OpenViking";
        rev = "v${version}";
        # TODO: replace with real hash after first build attempt
        hash = lib.fakeHash;
        fetchSubmodules = true;
      };

      lib = nixpkgs.lib;
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
    };
}
