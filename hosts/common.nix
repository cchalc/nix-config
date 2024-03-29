{ config, pkgs, nixpkgs, lib, ... }:
{
  imports =
    [
      ../programs/zsh/zsh.nix
      ../programs/neovim/neovim.nix
      ../programs/git.nix
    ];

  home = {
    stateVersion = "21.05";
    packages = with pkgs; [
#      cabal-install
      cachix
      gerrit
      buildkite-cli
      gawk
      jsonnet
      lorri
      mypy
      pandoc
      pyright
      ripgrep
      sqlite
      stack
      tree
      zathura
      kubectx
      watchexec
      lazydocker
      htop
      httpie
      k9s
      whois
      jq
      caddy
      nodePackages.javascript-typescript-langserver
      nodePackages.uglify-js
    ];
  };

  # program specifications
  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv = {
        enable = true;
      };
    };

  zsh.enable = true;

  fzf = {
    enable = true;
  };
  bat = {
    enable = true;
    config.theme = "TwoDark";
  };

  gpg = {
    enable = true;
  };

};


#  xdg.configFile."poetry/pypoetry".source = ../programs/dev/poetry.conf;
  xdg.configFile = {
    "alacritty/alacritty.yml".source = ../programs/alacritty.yml;
    "oh-my-zsh/plugins/nix-shell".source = pkgs.fetchFromGitHub {
      owner = "chisui";
      repo = "zsh-nix-shell";
      rev = "f8574f27e1d7772629c9509b2116d504798fe30a";
      sha256 = "0svskd09vvbzqk2ziw6iaz1md25xrva6s6dhjfb471nqb13brmjq";
    };
  };

#  xdg.configFile."alacritty/alacritty.yml".source = ../programs/alacritty.yml;
#  xdg.configFile."oh-my-zsh/plugins/nix-shell".source = pkgs.fetchFromGitHub {
#    owner = "chisui";
#    repo = "zsh-nix-shell";
#    rev = "f8574f27e1d7772629c9509b2116d504798fe30a";
#    sha256 = "0svskd09vvbzqk2ziw6iaz1md25xrva6s6dhjfb471nqb13brmjq";
#  };

  home.file.".ipython/profile_default/ipython_config.py".text = ''
    c.InteractiveShellApp.extensions = ["autoreload"]
    c.InteractiveShellApp.exec_lines = ["%autoreload 2"]
    '';
}
