{config, lib, pkgs, ...}:
{
	imports = 
	[
		./direnv
		./fish
		./git
		./nvim
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
			devenv
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
		kitty = {
			enable = true;
			extraConfig = builtins.readFile ./kitty;
		};
		zellij = {
			enable = true;
			enableFishIntegration = true;
		};
	};
}
