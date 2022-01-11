{
  description = "NixOS configuration and home-manager configurations for mac and debian gnu/linux";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
      };

    # Other sources
    comma = { url = github:Shopify/comma; flake = false; };
    flake-compat = { url = github:edolstra/flake-compat; flake = false; };
    flake-utils.url = github:numtide/flake-utils;

  };
  outputs = {self, darwin, home-manager, flake-utils, nixpkgs, nur, ...}@inputs:
    let
      homeManagerConfFor = config: { ... }: {
        nixpkgs.overlays = [ ];
        imports = [ config ];
      };
      darwinSystem = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        modules = [
          ./hosts/macbook/darwin-configuration.nix
          home-manager.darwinModules.home-manager {
            home-manager.users.cchalc = homeManagerConfFor ./hosts/macbook/home.nix;
          }
        ];
      };

          in {
      #overlay = import ./overlay

      #homeConfigurations = {
      #  macbook = inputs.home-manager.lib.homeManagerConfiguration {
      #    darwinSystem;
      #    };
      #};

      darwinConfigurations = {
        databricks = darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = [
            ./hosts/macbook/darwin-configuration.nix
            home-manager.darwinModules.home-manager {
              home-manager.users.cchalc = homeManagerConfFor ./hosts/macbook/home.nix;
            }
          ];
        };
      };
         
      defaultPackage.x86_64-darwin = darwinSystem.system;
      databricks = self.darwinConfigurations.databricks.system;
    };
}
