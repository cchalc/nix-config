{
  config,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg: true;
  home = {
    stateVersion = "23.11";
    username = "christopher.chalcraft";
    homeDirectory = "/Users/christopher.chalcraft";

    file.".config" = {
      source = ./config;
      recursive = true;
    };
    file.".zprofile" = {source = ./.zprofile;};
    file.".zshrc" = {source = ./.zshrc;};
  };

  xdg.enable = true;

  programs.home-manager.enable = true;
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.configHome}/gnupg";
  };

  imports = [
    ./modules/home-manager
  ];

  packages = with pkgs; [
    zed-editor
  ];
}
