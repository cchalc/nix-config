{ config, lib, ... }:
let
  # Rex (superlogical) is a beta terminal installed by hand from the beta
  # program, so there is no package here — only its config. Known-good with
  # rex 0.1.0-preview.14 (`rex version`). The CLI ships inside the server
  # bundle; activation calls it by full path because PATH is minimal there.
  rexBin = "${config.home.homeDirectory}/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex";

  # The whole ~/.config/rex dir is linked out-of-store (straight to the repo,
  # not a read-only nix-store copy) so new lua modules and `rex do` scripts go
  # live without a switch: edit, then `rex config reload`. Rex does not watch
  # the file. Appearance/UI prefs are app-owned (com.superlogical.rex plist)
  # and deliberately not managed here.
  repo = "${config.home.homeDirectory}/Config/nix-config";
in {
  xdg.configFile."rex".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/modules/home-manager/rex/config";

  # Rex created ~/.config/rex as a real (empty) directory, which would block
  # the link. Remove it only while it is empty; anything else needs a human.
  home.activation.rexPrepare = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    dir="${config.xdg.configHome}/rex"
    if [ -d "$dir" ] && [ ! -L "$dir" ]; then
      if rmdir "$dir" 2>/dev/null; then
        echo "rex: removed empty $dir so it can be linked"
      else
        echo "rex: $dir is a non-empty directory; move its contents into the repo and remove it"
      fi
    fi
  '';

  # Validate the config and push it to a running server. Never installs
  # anything and never fails the switch. The terminfo and skill checks only
  # print a hint; running their setup commands is left to the user.
  home.activation.rexConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    rex="${rexBin}"
    if [ -x "$rex" ]; then
      if ! "$rex" config check --autostart=false >/dev/null 2>&1; then
        echo "rex: config check failed — run: rex config check"
      elif "$rex" server status --autostart=false >/dev/null 2>&1; then
        "$rex" config reload --autostart=false >/dev/null 2>&1 \
          || echo "rex: config reload failed — run: rex config reload"
      fi

      if "$rex" terminfo status --autostart=false 2>/dev/null | grep -q '^Not ready'; then
        echo "rex: terminfo not installed — run: rex terminfo setup"
      fi

      if "$rex" skill status --json --autostart=false 2>/dev/null \
        | grep -Eq '"state": *"(missing|outdated)"'; then
        echo "rex: agent skill or hooks missing or outdated — run: rex skill setup"
      fi
    fi
  '';

  # Fish: completions and short abbreviations for the rex CLI. Completions are
  # cached under ~/.cache/rex and regenerated only when the rex binary is newer,
  # so shell start does not run `rex completion` every time.
  programs.fish = {
    interactiveShellInit = lib.mkAfter ''
      # Rex completions (cached; see modules/home-manager/rex/default.nix)
      if command -q rex
          set -l __rex_bin (command -s rex)
          set -l __rex_cache "$HOME/.cache/rex/completion.fish"
          if not test -s "$__rex_cache"; or test "$__rex_bin" -nt "$__rex_cache"
              mkdir -p "$HOME/.cache/rex"
              rex completion fish --autostart=false >"$__rex_cache.tmp" 2>/dev/null; and mv -f "$__rex_cache.tmp" "$__rex_cache"
          end
          test -s "$__rex_cache"; and source "$__rex_cache"
      end
    '';

    shellAbbrs = {
      rx = "rex";
      rxc = "rex config check";
      rxr = "rex config reload";
      rxk = "rex keymap";
      rxd = "rex do";
      rxa = "rex actions";
    };
  };
}
