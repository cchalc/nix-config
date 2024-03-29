{ pkgs, nix, nixpkgs, config, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "vscode"
    "vscode-with-extensions"
  ];

  environment.systemPackages = with pkgs;
    [
#      ( python39.withPackages (ps: with ps; [ pip flake8 black pynvim ipython ]) )
      ( python310.withPackages (ps: with ps; [ pip flake8 black pynvim ipython ]) )
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
      unixODBC
      iosevka
    ];

  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      fira-code
      fira-code-symbols
      iosevka
      aileron
    ];
  };

  programs.zsh.enable = true; # set in common.nix with direnv

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
#    nixPath = lib.mkForce [
#      "nixpkgs=${nixpkgs}"
#    ];
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
