{config, lib, pkgs, ...}:
{
	imports = 
	[
		./direnv
		./fish
		./git
		./nvim
		./kitty.nix
	];

	home = {
		packages = with pkgs; [
			fd
			jq
			raycast
			ripgrep
			rustup
			starship
			stylua
			yabai
			zoxide
			tree
			htop
			fzf
			cachix
			pandoc
			whois
		];
	};

  programs = {
    fzf = {
      enable = true;
    };
    bat = {
      enable = true;
      config.theme = "TwoDark";
    };
	};
}
