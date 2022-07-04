{ pkgs, nix, nixpkgs, config, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "vscode"
    "vscode-with-extensions"
  ];

  environment.systemPackages = with pkgs;
    [
      ( python38.withPackages (ps: with ps; [ pip flake8 black pynvim ipython python-language-server.override { pylint = null; } ]) )
      go
      ffmpeg
      gnupg
      openssl
      yarn
      coreutils
      ripgrep
      fzf
      zoxide
      irssi
      tig
      tree
      wget
      fswatch
      sqlite
      nodejs
      docker
      reattach-to-user-namespace
      alacritty
      ghc
      cabal-install
      poetry
      gh
      #jre8 # for databricks-connect
      exercism
    ];

  fonts = {
    enableFontDir = true;
    fonts = with pkgs; [
      fira-code
      fira-code-symbols
#      iosevka
      aileron
    ];
  };

  programs.zsh.enable = true;

  #programs.gpg = {
  #  enable = true;
  #};

  system.stateVersion = 4;
  users = {
    users."christopher.chalcraft" = {
      home = /Users/christopher.chalcraft;
    };
  };

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
