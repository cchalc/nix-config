{ pkgs, ... }: {
  # Television (`tv`) fuzzy finder. Config + cable channels live in
  # config/television/, symlinked to ~/.config/television via the top-level
  # home.file.".config". Fish integration (`tv init fish | source`) and the
  # ctrl-t smart-autocomplete binding are wired in the fish module.
  home.packages = with pkgs; [ television ];
}
