{ config, lib, pkgs, ... }: {
  nixpkgs.config.allowUnfreePredicate = pkg: true;

  home = {
    stateVersion = "23.11";
    username = "christopher.chalcraft";
    homeDirectory = "/Users/christopher.chalcraft";

    sessionPath = [
      "$HOME/.npm-global/bin"
      "$HOME/.cache/pnpm"
      "$HOME/.cache/.bun/bin" # bun global installs (hunk lives here — see modules/home-manager/git/default.nix for context)
      "$HOME/.cache/cargo/bin"
      "$HOME/.local/bin"
      "$HOME/superset/bin" # installer-managed; config.fish is a nix symlink so the installer's PATH edit fails — add it here instead
      "/Applications/Obsidian.app/Contents/MacOS"
    ];

    sessionVariables = {
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
      CARGO_HOME = "$HOME/.cache/cargo";
      PNPM_HOME = "$HOME/.cache/pnpm";
      JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
      VISUAL = "nvim";
      EDITOR = "nvim";

      # metabase backend (local postgres — bootstrap with the commands below)
      MB_DB_TYPE = "postgres";
      MB_DB_HOST = "localhost";
      MB_DB_PORT = "5432";
      MB_DB_DBNAME = "metabase";
      MB_DB_USER = "metabase";
      MB_DB_PASS = "metabase"; # local-only dev creds, fine in plaintext
      PGDATA = "$HOME/.local/share/postgres"; # default data dir for pg_ctl/initdb
    };

    activation.createUserBins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p \
        $HOME/.npm-global/bin \
        $HOME/.cache/pnpm \
        $HOME/.cache/cargo/bin \
        $HOME/.local/bin
    '';

    file.".config" = {
      source = ./config;
      recursive = true;
    };
    file.".zprofile" = { source = ./.zprofile; };
    file.".zshrc" = { source = ./.zshrc; };
  };

  xdg.enable = true;
  programs.home-manager.enable = true;
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.configHome}/gnupg";
  };

  imports = [
    ./modules/home-manager
  ];
}
