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
			#python
			(python3.withPackages (ps: with ps; [
				pip
				virtualenv
				hatch
			]))
			uv
			python3Packages.ipython
			python3Packages.parso
			python3Packages.twine

			#databricks
			python312Packages.databricks-cli
			python312Packages.databricks-sql-connector
			python311Packages.databricks-connect

			#other
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
