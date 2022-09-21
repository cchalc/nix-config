{ lib, config, pkgs, nixpkgs, ... }:
let
  nixFlakes = (pkgs.writeScriptBin "nixFlakes" ''
      exec ${pkgs.nixUnstable}/bin/nix --experimental-features "nix-command flakes" "$@"
    '');
in {
  imports = [
   ../common.nix
 ];
 home.packages = with pkgs; [
   zlib
   terraform
   cue
   cuetools
   nixFlakes

   # cloud
   azure-cli
   google-cloud-sdk

   # editor
   vscode-with-extensions
   helix
 ];

 nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
   "vscode"
   "vscode-with-extensions"
 ];
}
