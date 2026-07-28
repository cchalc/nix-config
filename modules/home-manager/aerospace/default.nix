{ pkgs, ... }: {
  # AeroSpace tiling window manager (replaces yabai). Config lives in
  # config/aerospace/aerospace.toml, symlinked to ~/.config/aerospace via the
  # top-level home.file.".config" in home.nix.
  #
  # AeroSpace is a menu-bar app: after `home-manager switch`, launch it once,
  # grant Accessibility permission (System Settings → Privacy & Security →
  # Accessibility), then enable "start at login" from its menu-bar icon (the
  # config keeps start-at-login = false so nix doesn't fight the app's own
  # login-item registration).
  home.packages = with pkgs; [ aerospace ];
}
