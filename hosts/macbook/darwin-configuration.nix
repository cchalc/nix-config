{ pkgs, nix, nixpkgs, config, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "vscode"
    "vscode-with-extensions"
  ];

  environment.systemPackages = with pkgs;
    [
      ( python38.withPackages (ps: with ps; [ pip flake8 black pynvim ipython python-language-server.override { pylint = null; } ]) )
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
    ];

  fonts = {
    enableFontDir = true;
    fonts = with pkgs; [
      fira-code
      iosevka
      aileron
    ];
  };

  programs.zsh.enable = true;

  system.stateVersion = 4;
  users = {
    users.cchalc = {
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
