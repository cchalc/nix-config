{ pkgs, lib, ... }:
with lib;
let
  smosModule = smos.homeManagerModules.${system}.default
in
{
  imports = [
    smosModule
    # [...]
  ];
  programs.smos = {
    enable = true;
  };
}
