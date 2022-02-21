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
   vscode-with-extensions
   terraform
   cue
   cuetools
   google-cloud-sdk
   nixFlakes

   # azure
   azure-cli
 ];

 nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
   "vscode"
   "vscode-with-extensions"
 ];
}
