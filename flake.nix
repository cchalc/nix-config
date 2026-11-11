{
  description = "nixconf";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    # gh only: GTM Genie needs gh >= 2.102.0. A full nixpkgs bump (2026-10-17) breaks azure-cli
    # (python fabric marked broken), so gh alone comes from this pin. Drop once nixpkgs moves past it.
    nixpkgs-gh.url = "github:nixos/nixpkgs/7a6522c868711d06e3a520bbcdfafe9806f4337f";
    # hunk: blocked on corp firewall — npm registry deps unreachable via Nix sandbox. Installed via bun + Databricks npm proxy instead.
    # hunk = {
    #   url = "github:modem-dev/hunk";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: {
    homeConfigurations = {
      "christopher.chalcraft" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [./home.nix];
        extraSpecialArgs = {
          inherit inputs;
        };
      };
    };
  };
}
