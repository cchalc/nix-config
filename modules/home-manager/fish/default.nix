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
      set -Ux CARGO_HOME ~/.cache/cargo/
      set -Ux PNPM_HOME ~/.cache/pnpm/
      set -U fish_greeting

      fish_add_path $PNPM_HOME
      fish_add_path $CARGO_HOME/bin/

      set -xg XDG_CONFIG_HOME ~/.config
      set -xg VISUAL nvim

      # Makes C^z go back to the background task (vim 99% of the time)
      bind \cz 'fg'

      starship init fish | source
      zoxide init fish | source

			set -g SHELL ${pkgs.fish}/bin/fish
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
    };

    plugins = [
    ];
  };
}
