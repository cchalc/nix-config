{ config, lib, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      grep = "grep --color=auto";
      diff = "diff --color=auto";
      dc = "docker compose";
      iq = "instruqt";
      szsh = "source ~/.zshrc";
      cat = "bat";
      garbage = "nix-collect-garbage";
      we = "watchexec";

      # Navigation;
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
    };
    enableAutosuggestions = true;
    enableCompletion = true;
    autocd = true;
    history.extended = true;
    initExtraBeforeCompInit = builtins.readFile ./zshrc;
    oh-my-zsh = {
      enable = true;
      theme = "af-no-magic";
      plugins = [
        "git"
        "vi-mode"
        "tmuxinator"
        "nix-shell"
        "direnv"
      ];
    };
  };
  programs.fzf.enableZshIntegration = true;

  home.file.".config/oh-my-zsh/themes/af-no-magic.zsh-theme".source = ./af-no-magic.zsh-theme;
}
