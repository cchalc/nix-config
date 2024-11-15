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
			(python3.withPackages (ps: with ps; [
				pip
				virtualenv
				hatch
			]))
			uv
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
		python312 = {
			enable = true;
		};
	};

  home.sessionVariables = {
    PYTHONPATH = "${pkgs.python3}/lib/python${pkgs.python3.pythonVersion}/site-packages";
  };
}
