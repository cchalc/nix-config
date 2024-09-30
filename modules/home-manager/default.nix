{pkgs, ...}:
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
			cachix
			pandoc
			whois
		];

		programs = {
			fzf = {
				enable = true;
			};
			bat = {
				enable = true;
				config.theme = "TwoDark";
			};
		};
	};
}
