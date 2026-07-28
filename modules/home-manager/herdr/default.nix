{ pkgs, ... }:
let
  # herdr is not in nixpkgs and building from its flake compiles Rust from
  # crates.io (risks the same corp-firewall wall that blocked hunk), so we pin
  # the prebuilt macOS aarch64 release binary. Version bumps: edit `version`,
  # then `nix-prefetch-url <url>` + `nix hash to-sri --type sha256 <hash>`.
  herdr = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "herdr";
    version = "0.7.5";

    src = pkgs.fetchurl {
      url = "https://github.com/ogulcancelik/herdr/releases/download/v${version}/herdr-macos-aarch64";
      hash = "sha256-NzUFRrABJVWUO5Lq+WJmXeTiZDlbrrRCJ7gBXo/1sNY=";
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
in {
  home.packages = [ herdr ];
}
