{pkgs, ...}: {
  programs.tmux = {
    enable = true;

    # Options handled natively by Home Manager
    prefix = "C-s";
    mouse = true;
    keyMode = "vi";
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator

      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_window_status_style "rounded"
          set -g status-left ""
          set -g status-right "#{E:@catppuccin_status_application} #{E:@catppuccin_status_session}"
        '';
      }
    ];

    extraConfig = builtins.readFile ./tmux.conf;
  };
}