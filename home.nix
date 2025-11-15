{ config, pkgs, lib, ... }:

let
  isMac = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  configDir = "${config.home.homeDirectory}/.config/nix-config";
in
{
  nixpkgs.config.allowUnfree = true;

  # Just install packages - don't manage dotfiles
  home.packages = with pkgs; [
    # Core utilities
    git
    gh
    curl
    wget
    tree
    
    # Modern CLI tools
    fzf
    ripgrep
    zoxide
    btop
    bat
    eza
    fd
    
    # Dev tools
    neovim
    tmux
    
    # LSPs
    lua-language-server
    nil
    nodePackages.bash-language-server
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
    pyright
    rust-analyzer
    gopls
    
    # Formatters
    stylua
    nixpkgs-fmt
    black
    nodePackages.prettier
    
    # Additional
    jq
    yq
  ] ++ lib.optionals isMac [
    # macOS-specific
  ] ++ lib.optionals isLinux [
    # Linux-specific
  ];

home.file = {
  ".zshrc".source = ./zshrc;
  ".p10k.zsh".source = ./p10k.zsh;
  ".config/tmux/tmux.conf".source = ./tmux.conf;
  
  ".config/nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nvim";
    recursive = true;
  };
};

  # Install oh-my-zsh and TPM
  home.activation = {
    installDeps = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Install oh-my-zsh if missing
      if [ ! -d "$HOME/.oh-my-zsh" ]; then
        ${pkgs.curl}/bin/curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- --unattended
      fi
      
      # Install zsh plugins
      if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
        ${pkgs.git}/bin/git clone https://github.com/zsh-users/zsh-autosuggestions \
          $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
      fi
      
      if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
        ${pkgs.git}/bin/git clone https://github.com/zsh-users/zsh-syntax-highlighting \
          $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
      fi
      
      # Install powerlevel10k
      if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        ${pkgs.git}/bin/git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
          $HOME/.oh-my-zsh/custom/themes/powerlevel10k
      fi
      
      # Install TPM
      if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm \
          $HOME/.tmux/plugins/tpm
      fi
    '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.home-manager.enable = true;
}
