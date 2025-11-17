#!/usr/bin/env bash
set -e

echo "🚀 Bootstrap: Nix Dotfiles Setup"
echo "=================================="
echo ""

# Detect system
if [[ "$OSTYPE" == "darwin"* ]]; then
  SYSTEM="darwin"
  if [[ $(uname -m) == "x86_64" ]]; then
    ARCH="x86_64-darwin"
  else
    ARCH="aarch64-darwin"
  fi
else
  SYSTEM="linux"
  if [[ $(uname -m) == "aarch64" ]]; then
    ARCH="aarch64-linux"
  else
    ARCH="x86_64-linux"
  fi
fi

USERNAME=$(whoami)
HOSTNAME=$(hostname -s)
CONFIG_NAME="${USERNAME}@${HOSTNAME}"

echo "📍 Detected System: $ARCH"
echo "👤 Config Name: $CONFIG_NAME"
echo ""

# Install Nix if not present
if ! command -v nix &> /dev/null; then
  echo "📦 Installing Nix..."
  if [[ "$SYSTEM" == "darwin" ]]; then
    sh <(curl -L https://nixos.org/nix/install)
  else
    sh <(curl -L https://nixos.org/nix/install) --daemon
  fi

  # Source nix
  if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  fi
else
  echo "✅ Nix already installed"
fi

# Enable flakes
echo "🔧 Enabling flakes..."
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

# Add GitHub token to avoid API rate limits (if gh is authenticated)
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
  echo "access-tokens = github.com=$(gh auth token)" >> ~/.config/nix/nix.conf
  # Setup gh as git credential helper for HTTPS
  gh auth setup-git 2>/dev/null || true
  echo "✅ GitHub authentication configured"
else
  echo "⚠️  GitHub CLI (gh) not found or not authenticated"
  echo "   To avoid API rate limits, you can:"
  echo "   1. Install gh and run: gh auth login"
  echo "   2. Or manually add to ~/.config/nix/nix.conf:"
  echo "      access-tokens = github.com=YOUR_TOKEN_HERE"
  echo ""
  echo "   Get a token at: https://github.com/settings/tokens"
  echo "   (Continuing without authentication may hit rate limits...)"
  echo ""
  read -p "Press Enter to continue..."
fi

# Clone repo if not already present
if [ ! -d ~/.config/nix-config ]; then
  echo "📥 Cloning dotfiles..."
  git clone https://github.com/IslamTayeb/dotfiles.git ~/.config/nix-config
else
  echo "✅ Dotfiles already cloned"
fi

cd ~/.config/nix-config

# Make scripts executable
chmod +x scripts/*.sh

# Check if this machine is already configured in flake.nix
if ! grep -q "$CONFIG_NAME" flake.nix; then
  echo ""
  echo "⚠️  This machine ($CONFIG_NAME) is not configured in flake.nix yet."
  echo ""
  echo "Please add to flake.nix homeConfigurations:"
  echo "  \"$CONFIG_NAME\" = mkHomeConfig \"$ARCH\" \"$USERNAME\" [ ];"
  echo ""
  read -p "Press Enter after you've added it (or Ctrl+C to exit)..."
fi

# Run installation
echo ""
echo "🏗️  Running installation..."
./scripts/install.sh

# Ensure zsh is the default shell
echo ""
echo "🐚 Setting zsh as default shell..."
ZSH_PATH=$(command -v zsh)
if [ -n "$ZSH_PATH" ]; then
  # Add zsh to /etc/shells if not already there
  if ! grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
  fi

  # Change default shell to zsh
  if [ "$SHELL" != "$ZSH_PATH" ]; then
    sudo chsh -s "$ZSH_PATH" "$USERNAME"
    echo "✅ Default shell set to zsh"
    export SHELL="$ZSH_PATH"
  else
    echo "✅ Shell already set to zsh"
  fi
else
  echo "⚠️  Could not find zsh path, skipping shell change"
fi

echo ""
echo "✨ Setup complete!"
echo ""
echo "Next steps:"
echo "  - Restart your terminal or reconnect SSH"
echo "  - Open nvim to let LazyVim install plugins"
echo "  - Run 'tmux' and press Ctrl-l then Shift-I to install plugins"
echo ""
echo "Optional:"
echo "  - Run './scripts/setup-cron.sh' to enable auto-commit"
echo ""
