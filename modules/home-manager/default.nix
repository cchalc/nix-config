{ config, lib, pkgs, ... }:
{
  imports = [
    ./aerospace
    ./direnv
    ./fish
    ./git
    ./herdr
    ./nvim
    ./jujutsu
    ./sketchybar
    ./television
    ./tmux
  ];

  home = {
    packages = with pkgs; [
      # python
      (python312.withPackages (ps: with ps; [
        pip
        virtualenv
        hatch
      ]))
      uv
      python3Packages.ipython
      python3Packages.parso
      python3Packages.twine

      # databricks
      # python312Packages.databricks-cli
      # python312Packages.databricks-sql-connector
      # python312Packages.databricks-connect
      jdk17
      nodejs_22
      yarn
      duckdb
      bun
      pnpm

      # elixir
      elixir_1_15
      livebook

      # other
      fd
      jq
      yq
      raycast
      ripgrep
      rustup
      starship
      stylua
      zoxide
      tree
      htop
      fzf
      devenv
      cachix
      pandoc
      whois
      wget
      just

			# ai
			opencode

      # training
      exercism

      # cloud stuff
      google-cloud-sdk
      awscli2
      pgcli
      postgresql_16 # local backend for metabase; bootstrap manually (see home.nix MB_DB_* vars)
      metabase

			# macOS
			terminal-notifier
    ];
  };

  programs = {
    fzf.enable = true;

    atuin = {
      enable = true;
      enableFishIntegration = true;
    };

    bat = {
      enable = true;
      config.theme = "TwoDark";
    };

    kitty = {
      enable = true;
      extraConfig = builtins.readFile ./kitty;
    };

    zellij = {
      enable = false;
      enableFishIntegration = true;
    };

    ghostty = {
      enable = true;
      package = pkgs.ghostty-bin; # macOS
      # Integration is sourced manually in the fish module instead: the built-in
      # emits an unguarded `source`, which breaks when a ghostty-based terminal
      # (e.g. cmux) sets GHOSTTY_RESOURCES_DIR to a bundle lacking the file.
      enableFishIntegration = false;
      settings = {
        font-family = "JetBrainsMono Nerd Font";  # or any other Nerd Font
        font-size = 14;
        font-thicken = true;
        theme = "Catppuccin Macchiato";
        background-opacity = 0.98;
				foreground = "#cad3f4";
				background = "#24273a";
      };
    };
  };
}
