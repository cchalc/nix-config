{
  pkgs,
  config,
  ...
}:
{
  programs.fish = {
    enable = true;
    shellInit = ''
      # Nix
      if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
        source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
      end
      # End Nix
    '';
    interactiveShellInit = ''
      set -U fish_greeting

      # Makes C^z go back to the background task (vim 99% of the time)
      bind \cz 'fg'

      starship init fish | source
      zoxide init fish | source

      # television (tv) shell integration. Binds ctrl-t to tv smart-autocomplete
      # (superseding fzf's ctrl-t file widget); atuin keeps ctrl-r. See
      # config/television/config.toml [shell_integration.keybindings].
      tv init fish | source

      set -g SHELL ${pkgs.fish}/bin/fish

      # Ghostty shell integration (sourced manually — programs.ghostty's built-in
      # integration is disabled; see modules/home-manager/default.nix). Guard on
      # the FILE existing, not just the var: ghostty-based terminals like cmux set
      # GHOSTTY_RESOURCES_DIR to a bundle that ships terminfo/themes but no
      # shell-integration, which would otherwise error on every shell start.
      if set -q GHOSTTY_RESOURCES_DIR
        set -l __ghostty_integration "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
        test -f "$__ghostty_integration"; and source "$__ghostty_integration"
      end
    '';
    shellAbbrs = {
      vi = "nvim";
      vim = "nvim";
      g = "git";
      dc = "docker compose";
      tf = "terraform";
      n = "nvim";
      k = "kubectl";
    };
    functions = {
      gi = {
        description = "Pick commit for interactive rebase";
        body = ''
          set -l commit (git log --oneline --decorate | fzf --preview 'git show (echo {} | awk \'{ print $1 }\')' | awk '{ print $1 }')
          if test -n "$commit"
            git rebase $commit~1 --interactive --autosquash
          end
        '';
      };
      gf = {
        description = "Fixup a commit then autosquash";
        body = ''
          set -l commit (git log --oneline --decorate | fzf --preview 'git show (echo {} | awk \'{ print $1 }\')' | awk '{ print $1 }')
          if test -n "$commit"
            git commit --fixup $commit
            GIT_SEQUENCE_EDITOR=true git rebase $commit~1 --interactive --autosquash
          end
        '';
      };
      gc = {
        description = "fzf git checkout";
        body = ''
          git checkout (git branch -a --sort=-committerdate |
            fzf --preview 'git log (echo {} | sed -E -e \'s/^(\+|\*)//\' | string trim) -- ' |
            sed -E -e 's/^(\+|\*)//' |
            xargs basename |
            string trim)
        '';
      };
    };
    shellAliases = {
      ga = "git add";
      gc = "git commit";
      gco = "git checkout";
      gcp = "git cherry-pick";
      gdiff = "git diff";
      gl = "git prettylog";
      gp = "git push";
      gs = "git status";
      gt = "git tag";
      ce = "echo 'export UV_PROJECT_ENVIRONMENT=$HOME/.virtualenvs/$(basename $PWD)' > .envrc";
      jd = "jj desc";
      jf = "jj git fetch";
      jn = "jj new";
      jp = "jj git push";
      js = "jj st";
      isaac = "dbexec repo run isaac";
    };
    plugins = [ ];
  };
}
