#!/usr/bin/env bash
set -e

echo "🚀 Setting up Nix dotfiles..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

# Set zsh as default shell if not already
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "🐚 Setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi

# Auto-install tmux plugins
echo "🔌 Installing tmux plugins..."
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    bash "$HOME/.tmux/plugins/tpm/bin/install_plugins"
fi

echo ""
echo "✨ Setup complete! Reloading shell..."
echo ""
echo "Next: Open nvim to let LazyVim install plugins"
echo "Update later with: ./update.sh"
echo ""
sleep 2
exec zsh
