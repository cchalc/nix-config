{
  config,
  pkgs,
  ...
}: {
  programs.neovim = {
    enable = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      #specific languages
      vim-nix
      vim-markdown
      vim-elixir
      vim-go
      vim-scala
      rust-vim
      vim-hcl
      vim-cue
      vim-pandoc
      vim-pandoc-syntax
      vim-toml

      # config
      vim-fugitive
      vim-airline
      vim-airline-themes

      #themes
      gruvbox
      vim-colors-solarized

      # utilities
      nerdtree
      ctrlp
      vim-abolish
      vim-repeat # cs"'...
      vim-commentary # gcap
      vim-indent-object # >aI
      vim-indent-guides
      vim-easy-align # vipga
      vim-eunuch # :Rename foo.rb
      vim-sneak
      #ale

      # extras
      vim-indent-guides
    ];
    extraConfig = builtins.readFile ./neovimrc;
  };
}
