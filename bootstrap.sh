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

# Determine where the dotfiles are
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're already in the dotfiles repo
if [ -f "$SCRIPT_DIR/flake.nix" ] && [ -f "$SCRIPT_DIR/home.nix" ]; then
  echo "✅ Running from dotfiles directory"
  cd "$SCRIPT_DIR"
elif [ -d ~/.config/nix-config ] && [ -f ~/.config/nix-config/flake.nix ]; then
  echo "✅ Using existing dotfiles at ~/.config/nix-config"
  cd ~/.config/nix-config
else
  echo "📥 Cloning dotfiles..."
  git clone https://github.com/IslamTayeb/dotfiles.git ~/.config/nix-config
  cd ~/.config/nix-config
fi

DOTFILES_DIR="$(pwd)"
echo "📁 Dotfiles location: $DOTFILES_DIR"

# Create symlink if needed (so home.nix can always find configs)
if [ "$DOTFILES_DIR" != "$HOME/.config/nix-config" ]; then
  if [ -e "$HOME/.config/nix-config" ] && [ ! -L "$HOME/.config/nix-config" ]; then
    echo "⚠️  Warning: ~/.config/nix-config exists and is not a symlink"
  else
    mkdir -p "$HOME/.config"
    ln -sfn "$DOTFILES_DIR" "$HOME/.config/nix-config"
    echo "🔗 Created symlink: ~/.config/nix-config -> $DOTFILES_DIR"
  fi
fi

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
