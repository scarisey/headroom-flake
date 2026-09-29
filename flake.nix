{
  description = "Headroom token compressor and harness wrappers";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (import nixpkgs { inherit system; })
        );
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.callPackage ./package.nix { };
        headroom = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.default ];
        };
      });

      checks = forAllSystems (pkgs: {
        modules = import ./tests/modules.nix {
          inherit pkgs;
          inherit (self) nixosModules homeManagerModules devenvModules;
        };
      });

      nixosModules.headroom = ./modules/nixos.nix;
      nixosModules.default = self.nixosModules.headroom;

      homeManagerModules.headroom = ./modules/home-manager.nix;
      homeManagerModules.default = self.homeManagerModules.headroom;

      devenvModules.headroom = ./modules/devenv.nix;
      devenvModules.default = self.devenvModules.headroom;
    };
}
