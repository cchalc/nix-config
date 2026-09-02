{ pkgs, ... }: {
  # AeroSpace tiling window manager (replaces yabai). Config lives in
  # config/aerospace/aerospace.toml, symlinked to ~/.config/aerospace via the
  # top-level home.file.".config" in home.nix.
  #
  # AeroSpace is a menu-bar app: after `home-manager switch`, grant it
  # Accessibility permission (System Settings → Privacy & Security →
  # Accessibility) — this is a one-time grant that must be done manually.
  # Start-at-login is now enabled in the config (aerospace.toml).
  home.packages = with pkgs; [ aerospace ];
}
