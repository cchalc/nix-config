{ config, pkgs, nixpkgs, lib, ... }:
{
  home.packages = with pkgs; [
#    # go
    go
    gofumpt
    gopls
#
#    # Haskell
#    ghc
#    haskellPackages.cabal-install
#    haskellPackages.stack
#
#    # JavaScript
#    nodejs
#    yarn
#
#    # lua
#    lua
    # nix
    nixfmt
    nixpkgs-fmt
    nixpkgs-review
    nixos-generators
#
    # python
    (python3.withPackages (ps: with ps; [ setuptools pip debugpy ]))
    poetry
    autoflake
    python3Packages.ipython
    python3Packages.parso
    python3Packages.twine

#    # rust
#    rustc
#    cargo
#    cargo-tarpaulin
#    perl # perl (this is required by rust)
#
    # neovim
    # Lunarvim requires fd and ripgrep as well.
    fd
    ripgrep
    neovim
    nodePackages.neovim
    python39Packages.pynvim
    tree-sitter
#
    # language servers
    rnix-lsp
    terraform-ls
    nodePackages.yaml-language-server
    nodePackages.typescript-language-server
    sumneko-lua-language-server
  ];
}
