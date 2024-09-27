{pkgs, ...}: {
  imports = [./direnv ./fish ./git ./nvim];
  home.packages = with pkgs; [
    erlang
    fd
    jq
    raycast
    ripgrep
    rustup
    starship
    stylua
    wezterm
    yabai
    zoxide
  ];
}
