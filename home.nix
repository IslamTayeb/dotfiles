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
    unzip

    # Modern CLI tools
    fzf
    ripgrep
    zoxide
    btop
    bat
    eza
    fd

    # Dev tools
    zsh
    bun
    neovim
    tmux

    # LSPs
    lua-language-server
    nil
    bash-language-server
    typescript-language-server
    vscode-langservers-extracted
    pyright
    rust-analyzer
    gopls

    # Formatters
    stylua
    nixpkgs-fmt
    black
    prettier

    # Additional
    jq
    pkgs."poppler-utils"
    yq
  ] ++ lib.optionals isMac [
    # macOS-specific
  ] ++ lib.optionals isLinux [
    xclip
  ];

  home.file = {
    # Shell configs
    ".zshenv".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/shell/zshenv";
    ".zshrc".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/shell/zshrc";
    ".p10k.zsh".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/shell/p10k.zsh";

    # Tmux
    ".config/tmux/tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/tmux/tmux.conf";

    # Ghostty (config is linked even when the app is not installed yet, so a
    # later `brew install --cask ghostty` picks it up with no extra steps)
    ".config/ghostty/config.ghostty".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/ghostty/config.ghostty";

    # Development tools
    ".config/nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/nvim";
      recursive = true;
    };

    ".config/btop" = {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/btop";
      recursive = true;
    };

    ".config/neofetch" = {
      source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/neofetch";
      recursive = true;
    };

    # OpenCode
    ".config/opencode/.gitignore".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/opencode/.gitignore";
    ".config/opencode/bun.lock".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/opencode/bun.lock";
    ".config/opencode/opencode.json".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/opencode/opencode.json";
    ".config/opencode/package.json".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/opencode/package.json";
    ".config/opencode/tui.json".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/opencode/tui.json";
    ".config/opencode/themes/gruvbox-transparent.json".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/configs/opencode/themes/gruvbox-transparent.json";
  };

  # Install oh-my-zsh and TPM
  home.activation = {
    installDeps = lib.hm.dag.entryAfter [ "installPackages" "linkGeneration" ] ''
      export PATH="${lib.makeBinPath [ pkgs.zsh pkgs.git pkgs.curl ]}:$PATH"
      export CHSH=no
      export RUNZSH=no
      export KEEP_ZSHRC=yes

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

    setupOpencode = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      opencode_dir="$HOME/.config/opencode"
      config_dir="${configDir}/configs/opencode"

      # Copy tools (can't be symlinks — bun needs real files for module resolution)
      mkdir -p "$opencode_dir/tools"
      if [ -f "$config_dir/tools/read_pdf.ts" ]; then
        cp -f "$config_dir/tools/read_pdf.ts" "$opencode_dir/tools/read_pdf.ts"
      fi

      if [ -f "$opencode_dir/package.json" ] && {
        [ ! -d "$opencode_dir/node_modules" ] ||
        [ "$opencode_dir/package.json" -nt "$opencode_dir/node_modules" ] ||
        [ "$opencode_dir/bun.lock" -nt "$opencode_dir/node_modules" ];
      }; then
        echo "Installing OpenCode tool dependencies..."
        ${pkgs.bun}/bin/bun install --cwd "$opencode_dir" --frozen-lockfile
      fi
    '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.home-manager.enable = true;
}
