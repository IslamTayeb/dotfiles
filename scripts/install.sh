#!/usr/bin/env bash
set -e

echo "🚀 Setting up Nix dotfiles..."

# Get the directory where this script is located (go to parent of scripts dir)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

# Initialize git if not already done
if [ ! -d ".git" ]; then
  echo "📦 Initializing git repository..."
  git init
  git add .
  git commit -m "Initial commit"
fi

# Build and activate Home Manager configuration
echo "🏗️  Building Home Manager configuration..."

# Detect the system and username
if [[ "$OSTYPE" == "darwin"* ]]; then
  SYSTEM="aarch64-darwin"
  if [[ $(uname -m) == "x86_64" ]]; then
    SYSTEM="x86_64-darwin"
  fi
else
  SYSTEM="x86_64-linux"
  if [[ $(uname -m) == "aarch64" ]]; then
    SYSTEM="aarch64-linux"
  fi
fi

USERNAME=$(whoami)
HOSTNAME=$(hostname -s)
CONFIG_NAME="${USERNAME}@${HOSTNAME}"

echo "📍 System: $SYSTEM"
echo "👤 Config: $CONFIG_NAME"

# Build and switch
nix run home-manager/master -- switch --flake ".#${CONFIG_NAME}" -b backup

echo "✅ Home Manager activated!"

# Auto-install tmux plugins
echo "🔌 Installing tmux plugins..."
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  bash "$HOME/.tmux/plugins/tpm/bin/install_plugins"
fi

echo ""
echo "✨ Setup complete!"
echo ""

# Ask about setting zsh as default shell
if [ "$SHELL" != "$(command -v zsh)" ]; then
  echo "🐚 Your current shell is: $SHELL"
  read -p "Would you like to set zsh as your default shell? (y/N) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🐚 Setting zsh as default shell..."
    if chsh -s "$(command -v zsh)" 2>/dev/null; then
      echo "✅ Default shell changed to zsh"
      echo "   (You may need to log out and back in for this to take effect)"
      SWITCH_TO_ZSH=true
    else
      echo "⚠️  Could not change default shell"
      echo "   You may need sudo permissions or to contact your system administrator"
      echo "   You can still use zsh by typing 'zsh' in your terminal"
      SWITCH_TO_ZSH=false
    fi
  else
    echo "ℹ️  Keeping current shell. You can always use zsh by typing 'zsh'"
    SWITCH_TO_ZSH=false
  fi
else
  echo "✅ Shell already set to zsh"
  SWITCH_TO_ZSH=true
fi

echo ""
echo "Next steps:"
echo "  - Open nvim to let LazyVim install plugins"
echo "  - Run 'tmux' and press Ctrl-l then Shift-I to install plugins"
echo "  - Update later with: ./scripts/update.sh"
echo ""

# Only exec zsh if user wants to switch
if [ "$SWITCH_TO_ZSH" = true ]; then
  echo "Starting zsh..."
  sleep 1
  exec zsh
fi
