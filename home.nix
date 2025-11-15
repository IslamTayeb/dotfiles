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
    # Shell configs
    ".zshrc".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/shell/zshrc";
    ".p10k.zsh".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/shell/p10k.zsh";

    # Tmux
    ".config/tmux/tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/tmux/tmux.conf";

    # Development tools
    ".config/nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/nvim";
      recursive = true;
    };

    ".config/btop" = {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/btop";
      recursive = true;
    };

    ".config/gh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/gh";
      recursive = true;
    };

    ".config/neofetch" = {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/neofetch";
      recursive = true;
    };

    ".config/zed" = {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/zed";
      recursive = true;
    };

    # macOS-specific tools
    ".config/karabiner" = lib.mkIf isMac {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/karabiner";
      recursive = true;
    };

    ".config/linearmouse" = lib.mkIf isMac {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/linearmouse";
      recursive = true;
    };

    ".config/sketchybar" = lib.mkIf isMac {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/sketchybar";
      recursive = true;
    };

    ".config/skhd" = lib.mkIf isMac {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/skhd";
      recursive = true;
    };

    ".config/yabai" = lib.mkIf isMac {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/yabai";
      recursive = true;
    };

    # Other tools
    ".config/rstudio" = {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/rstudio";
      recursive = true;
    };

    ".config/wireshark" = {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/wireshark";
      recursive = true;
    };
  };

  # Install oh-my-zsh and TPM
  home.activation = {
    installDeps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
