{ config, pkgs, lib, ... }:

let
  # Detect if we're on macOS or Linux
  isMac = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  # Allow unfree packages (for things like 1Password CLI if needed)
  nixpkgs.config.allowUnfree = true;

  # Packages to install
  home.packages = with pkgs; [
    # Core utilities
    git
    gh              # GitHub CLI
    curl
    wget
    tree
    
    # Modern CLI replacements
    fzf
    ripgrep
    zoxide
    btop
    bat             # Better cat
    eza             # Better ls
    fd              # Better find
    
    # Development tools
    neovim
    tmux
    
    # Language servers for LazyVim
    lua-language-server
    nil             # Nix LSP
    nodePackages.bash-language-server
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted  # HTML/CSS/JSON
    pyright         # Python LSP
    rust-analyzer   # Rust LSP
    gopls           # Go LSP
    
    # Formatters
    stylua          # Lua formatter
    black           # Python formatter
    nodePackages.prettier  # JS/TS/JSON formatter
    
    # Additional dev tools
    jq              # JSON processor
    yq              # YAML processor
    
  ] ++ lib.optionals isMac [
    # macOS-specific packages
    # Add Mac-specific tools here if needed
  ] ++ lib.optionals isLinux [
    # Linux-specific packages
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "islamtayeb";
    userEmail = "islam.moh.islamm@gmail.com";
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "nvim";
    };
    
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
    };
  };

  # Zsh configuration
  programs.zsh = {
    enable = true;
    
    # Load oh-my-zsh
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
      ];
      
      # Use powerlevel10k theme
      theme = "powerlevel10k";
      
      custom = "$HOME/.oh-my-zsh/custom";
    };
    
    initExtra = ''
      # Powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
      
      # Source p10k config if it exists
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      
      # Initialize zoxide
      eval "$(zoxide init zsh)"
      
      # fzf configuration
      export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    '';
    
    shellAliases = {
      vim = "nvim";
      vi = "nvim";
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      cat = "bat";
      cd = "z";  # Use zoxide
    };
  };

  # Tmux configuration - copy your existing config
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    keyMode = "vi";
    
    extraConfig = ''
      set-option -sa terminal-overrides ",xterm*:Tc"
      unbind C-b
      set -g prefix C-l
      bind C-l send-prefix
      
      # TPM plugins - will be managed by TPM itself
      set -g @plugin 'tmux-plugins/tpm'
      set -g @plugin 'tmux-plugins/tmux-sensible'
      set -g @plugin 'tmux-plugins/tmux-resurrect'
      set -g @plugin 'tmux-plugins/tmux-continuum'
      set -g @plugin 'tmux-prefix-highlight'
      
      set -g @continuum-save-interval '5'
      set -g @continuum-boot 'off'
      set -g @continuum-restore 'on'
      set -g @resurrect-capture-pane-contents 'on'
      set -g display-time 0
      
      set -g @plugin 'egel/tmux-gruvbox'
      set -g @tmux-gruvbox 'dark'
      
      # Initialize TPM (must be at the bottom)
      run '~/.tmux/plugins/tpm/tpm'
    '';
  };

  # Copy existing dotfiles that Nix doesn't manage directly
  home.file = {
    # Your existing nvim config (LazyVim will manage plugins)
    ".config/nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nvim";
      recursive = true;
    };
    
    # Powerlevel10k config if you have one
    ".p10k.zsh" = lib.mkIf (builtins.pathExists "${config.home.homeDirectory}/.p10k.zsh") {
      source = "${config.home.homeDirectory}/.p10k.zsh";
    };
  };

  # Install oh-my-zsh plugins that aren't built-in
  home.activation = {
    installOhMyZshPlugins = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Install zsh-autosuggestions
      if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
        ${pkgs.git}/bin/git clone https://github.com/zsh-users/zsh-autosuggestions \
          $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
      fi
      
      # Install zsh-syntax-highlighting
      if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
        ${pkgs.git}/bin/git clone https://github.com/zsh-users/zsh-syntax-highlighting \
          $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
      fi
      
      # Install powerlevel10k theme
      if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        ${pkgs.git}/bin/git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
          $HOME/.oh-my-zsh/custom/themes/powerlevel10k
      fi
      
      # Install TPM (Tmux Plugin Manager)
      if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm \
          $HOME/.tmux/plugins/tpm
      fi
    '';
  };

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
