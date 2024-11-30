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
			(python311Full.withPackages (ps: with ps; [
				pip
				virtualenv
				hatch
			]))
			uv
			python3Packages.ipython
			python3Packages.parso
			python3Packages.twine

			#databricks
			#python311Packages.databricks-cli
			#python311Packages.databricks-sql-connector
			#python311Packages.databricks-connect
			jdk17
			nodejs_22
			yarn
			duckdb

			#elixir
			elixir_1_15

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
