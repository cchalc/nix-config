{ config, lib, pkgs, ... }:
let
  # Modern Databricks CLI (Go binary, >=1.0.0). nixpkgs builds it with
  # buildGoModule, which fetches Go deps from proxy.golang.org — unreachable
  # through the corp firewall in the Nix sandbox on this machine (same reason
  # `hunk` isn't installed via Nix; see flake.nix). Package the official
  # prebuilt darwin_arm64 release instead so no Go build is needed.
  databricks-cli = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "databricks-cli";
    version = "1.9.0";
    src = pkgs.fetchurl {
      url = "https://github.com/databricks/cli/releases/download/v${version}/databricks_cli_${version}_darwin_arm64.tar.gz";
      hash = "sha256-yjD6sh2JG+kopZapTCBfXYDpY9GTJyiR6c9YlLsWa+k=";
    };
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      install -Dm755 databricks $out/bin/databricks
      runHook postInstall
    '';
    meta = {
      description = "Databricks CLI (official prebuilt release binary)";
      homepage = "https://github.com/databricks/cli";
      platforms = [ "aarch64-darwin" ];
      mainProgram = "databricks";
    };
  };
in
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
        # hatch's test suite needs pip/git network access and fails in the Nix
        # sandbox behind the corp firewall; skip its checks so it builds here.
        (hatch.overridePythonAttrs (_: { doCheck = false; doInstallCheck = false; }))
      ]))
      uv
      python3Packages.ipython
      python3Packages.parso
      python3Packages.twine

      # databricks
      databricks-cli # prebuilt release binary defined in the let block above (>=1.0.0)
      # python312Packages.databricks-sql-connector
      # python312Packages.databricks-connect
      jdk17
      nodejs_22
      yarn
      duckdb
      bun
      pnpm

      # elixir
      beamPackages.elixir_1_18 # was elixir_1_15; removed in nixpkgs bump (erlang_26 EOL)
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
      gemini-cli
      cursor-cli # Cursor's headless coding agent — provides the `cursor-agent` binary

      # training
      exercism

      # cloud stuff
      google-cloud-sdk
      awscli2
      pgcli
      postgresql_16 # local backend for metabase; bootstrap manually (see home.nix MB_DB_* vars)
      metabase
      flyctl   # fly.io CLI — omnigent persistence/sandbox (setup/PLAN Stage 3)
      railway  # railway.app CLI — omnigent persistence/sandbox (setup/PLAN Stage 3)

      # dev tooling
      aube # jdx/aube (mise is wired via programs.mise below)

      # macOS
      terminal-notifier
    ];
  };

  programs = {
    fzf = {
      enable = true;
      # Atuin owns ctrl-r (history) and television owns ctrl-t — see
      # modules/home-manager/fish/default.nix. Disabling fzf's history widget
      # resolves home-manager's "fzf and a history manager both configure Ctrl-R"
      # warning and makes the existing precedence explicit rather than
      # order-dependent (atuin merely sourced later and won by accident).
      historyWidget.command = "";
    };

    atuin = {
      enable = true;
      enableFishIntegration = true;
      # Mirrors omerxx/dotfiles atuin/config.toml. sync.records enables sync v2
      # data format but does nothing until the user runs `atuin login`/`register`.
      settings = {
        style = "compact";
        enter_accept = true;
        sync.records = true;
      };
    };

    # jdx/mise — per-project runtime/tool version manager. enableFishIntegration
    # defaults to true, so this also installs the fish activation hook that makes
    # per-directory mise.toml version switching work automatically.
    mise = {
      enable = true;
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

    # gh-dash — GitHub PRs/issues TUI (run with `gh dash`; needs `gh auth login`).
    # Ported from omerxx/dotfiles gh-dash/config.yml. Dropped the diffnav pager
    # and lazygit keybinding (neither installed here); the PR "code review"
    # keybinding uses wt/opencode/tmux, all present.
    gh-dash = {
      enable = true;
      settings = {
        prSections = [
          { title = "My Pull Requests"; filters = "is:open"; }
          { title = "Needs My Review"; filters = "is:open review-requested:@me"; }
          { title = "Involved"; filters = "is:open involves:@me -author:@me"; }
        ];
        issuesSections = [
          { title = "My Issues"; filters = "is:open author:@me"; }
          { title = "Assigned"; filters = "is:open assignee:@me"; }
          { title = "Involved"; filters = "is:open involves:@me -author:@me"; }
        ];
        notificationsSections = [
          { title = "All"; filters = ""; }
          { title = "Created"; filters = "reason:author"; }
          { title = "Participating"; filters = "reason:participating"; }
          { title = "Mentioned"; filters = "reason:mention"; }
          { title = "Review Requested"; filters = "reason:review-requested"; }
          { title = "Assigned"; filters = "reason:assign"; }
          { title = "Subscribed"; filters = "reason:subscribed"; }
          { title = "Team Mentioned"; filters = "reason:team-mention"; }
        ];
        repo = {
          branchesRefetchIntervalSeconds = 30;
          prsRefetchIntervalSeconds = 60;
        };
        defaults = {
          preview = {
            open = false;
            width = 70;
          };
          prsLimit = 20;
          prApproveComment = "LGTM";
          issuesLimit = 20;
          notificationsLimit = 20;
          view = "prs";
          layout = {
            prs = {
              updatedAt = { width = 5; };
              createdAt = { width = 5; };
              repo = { width = 20; };
              author = { width = 15; };
              authorIcon = { hidden = false; };
              assignees = { width = 20; hidden = true; };
              base = { width = 15; hidden = true; };
              lines = { width = 15; };
            };
            issues = {
              updatedAt = { width = 5; };
              createdAt = { width = 5; };
              repo = { width = 15; };
              creator = { width = 10; };
              creatorIcon = { hidden = false; };
              assignees = { width = 20; hidden = true; };
            };
          };
          refetchIntervalMinutes = 30;
        };
        keybindings = {
          prs = [
            {
              key = "C";
              name = "code review";
              command = ''tmux new-window -n "PR-{{.PrNumber}}" 'wt switch pr:{{.PrNumber}} -x "opencode --prompt `@code-reviewer: review-pr-for-this-branch`"'';
            }
          ];
        };
        theme = {
          colors = {
            text = {
              primary = "#F7F1FF";
              secondary = "#5AD4E6";
              inverted = "#F7F1FF";
              faint = "#3E4057";
              warning = "#FC618D";
              success = "#7BD88F";
            };
            background = {
              selected = "#535155";
            };
            border = {
              primary = "#948AE3";
              secondary = "#7BD88F";
              faint = "#3E4057";
            };
          };
          ui = {
            sectionsShowCount = true;
            table = {
              showSeparator = true;
              compact = true;
            };
          };
        };
        confirmQuit = false;
        showAuthorIcons = true;
        smartFilteringAtLaunch = true;
      };
    };
  };
}
