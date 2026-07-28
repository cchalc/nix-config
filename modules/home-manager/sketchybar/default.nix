{ pkgs, ... }: {
  # Sketchybar status bar + JankyBorders window outlines, driven by AeroSpace
  # (see modules/home-manager/aerospace). Config lives in config/sketchybar/,
  # symlinked to ~/.config/sketchybar via the top-level home.file.".config".
  #
  # sketchybar-app-font provides the app glyphs used by items/spaces.sh. macOS
  # may not pick it up until it's also installed in Font Book — the bar still
  # works without it (glyphs fall back to boxes). See readme for that step.
  #
  # AeroSpace launches `sketchybar` on startup and `borders` on workspace
  # change (after-startup-command / exec-on-workspace-change in aerospace.toml),
  # so neither needs a separate login item here.
  home.packages = with pkgs; [
    sketchybar
    jankyborders
    sketchybar-app-font
  ];
}
