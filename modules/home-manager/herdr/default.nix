{ config, pkgs, lib, ... }:
let
  # herdr is not in nixpkgs and building from its flake compiles Rust from
  # crates.io (risks the same corp-firewall wall that blocked hunk), so we pin
  # the prebuilt macOS aarch64 release binary. Version bumps: edit `version`,
  # then `nix-prefetch-url <url>` + `nix hash to-sri --type sha256 <hash>`.
  herdr = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "herdr";
    version = "0.9.5";

    src = pkgs.fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-macos-aarch64";
      hash = "sha256-+3fCIyoFqANUITgsiUOS9BdOTjihjkivPdApAVfDp+I=";
    };

    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/herdr
      runHook postInstall
    '';

    meta = {
      description = "Terminal workspace manager for AI coding agents";
      homepage = "https://herdr.dev";
      platforms = [ "aarch64-darwin" ];
      mainProgram = "herdr";
    };
  };

  # Everything herdr-related lives in this directory. config.toml is linked
  # out-of-store (straight to the repo file, not a read-only nix-store copy)
  # because herdr writes it back from its UI (theme picker, sound/toast
  # toggles) and live-reloads it. Only the one file is linked: the rest of
  # ~/.config/herdr is runtime state (sessions, sockets, logs) owned by herdr.
  repo = "${config.home.homeDirectory}/Config/nix-config";
in {
  home.packages = [ herdr ];

  xdg.configFile."herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/modules/home-manager/herdr/config.toml";

  # Agent integrations write hooks into each agent's own config (~/.claude,
  # ~/.pi, ~/.codex, ...), which herdr owns and versions, so they can't be
  # declarative. After a version bump, flag any that went stale — never install.
  home.activation.herdrIntegrations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    stale=$(${herdr}/bin/herdr integration status 2>/dev/null | grep -E ': outdated' | cut -d: -f1 || true)
    if [ -n "$stale" ]; then
      echo "herdr: outdated integrations — run:"
      for name in $stale; do echo "  herdr integration install $name"; done
    fi
  '';
}
