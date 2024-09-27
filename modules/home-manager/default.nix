{pkgs, ...}: {
  imports = [./direnv ./fish ./git ./nvim];
  home.packages = with pkgs; [
    fd
    jq
    raycast
    ripgrep
    rustup
    starship
    stylua
    yabai
    zoxide
  ];
}
