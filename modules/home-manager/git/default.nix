{pkgs, ...}: {
  home.packages = with pkgs; [
    gh
    git
    git-lfs
  ];
  xdg.configFile.git = {
    source = ./config;
    recursive = true;
  };

  # hunk integration (parked): corp firewall blocks registry.npmjs.org, so hunk's
  # bun2nix-generated FODs can't build under Nix. Installed imperatively via:
  #   BUN_CONFIG_REGISTRY=https://npm-proxy.cloud.databricks.com/ bun install -g hunkdiff
  # Binary lands at ~/.cache/.bun/bin/hunk (already on PATH via home.nix sessionPath).
  # To re-enable declarative Nix install when off corp net:
  #   1. Uncomment the `hunk` input in flake.nix (and `nix flake lock`).
  #   2. Migrate this module to `programs.git` (HM-managed) — needed so hunk's
  #      `enableGitIntegration` can write the pager config.
  #   3. Add: imports = [ inputs.hunk.homeManagerModules.default ];
  #   4. Add programs.hunk { enable = true; enableGitIntegration = true;
  #      settings = { theme = "graphite"; mode = "split"; line_numbers = true; }; };
}
