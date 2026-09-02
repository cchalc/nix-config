{ pkgs, ... }: {
  # Sketchybar status bar + JankyBorders window outlines, driven by AeroSpace
  # (see modules/home-manager/aerospace). Config lives in config/sketchybar/,
  # symlinked to ~/.config/sketchybar via the top-level home.file.".config".
  #
  # Fonts the bar needs (installed via home.packages → linked into
  # ~/Library/Fonts/HomeManager so macOS/sketchybar can resolve them):
  #   - sketchybar-app-font : app glyphs used by items/spaces.sh
  #   - nerd-fonts.jetbrains-mono : main bar FONT + separator glyph. omerxx's
  #     config hardcodes "SF Pro"/"Hack Nerd Font", which aren't installed on
  #     this machine, so config/sketchybar/sketchybarrc + items/spaces.sh are
  #     repointed at "JetBrainsMono Nerd Font" (already this machine's terminal
  #     font — has Bold/Semibold/Heavy/Black weights the bar uses).
  #
  # AeroSpace launches `sketchybar` on startup and `borders` on workspace
  # change (after-startup-command / exec-on-workspace-change in aerospace.toml),
  # so neither needs a separate login item here.
  home.packages = with pkgs; [
    sketchybar
    jankyborders
    sketchybar-app-font
    nerd-fonts.jetbrains-mono
  ];

  # Start the status bar at login, independent of AeroSpace. AeroSpace's
  # after-startup-command also runs `sketchybar`, which is harmless here
  # because KeepAlive means launchd already owns a single instance.
  launchd.agents.sketchybar = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.sketchybar}/bin/sketchybar" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/sketchybar.out.log";
      StandardErrorPath = "/tmp/sketchybar.err.log";
    };
  };
}
