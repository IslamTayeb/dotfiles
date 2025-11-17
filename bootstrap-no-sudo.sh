#!/usr/bin/env bash
set -e

echo "🚀 Bootstrap: Nix Dotfiles Setup (No Sudo)"
echo "==========================================="
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

# Check if Nix is present
if ! command -v nix &> /dev/null; then
  echo "❌ Nix is not installed!"
  echo ""
  echo "Please install Nix first:"
  if [[ "$SYSTEM" == "darwin" ]]; then
    echo "  sh <(curl -L https://nixos.org/nix/install)"
  else
    echo "  sh <(curl -L https://nixos.org/nix/install) --daemon"
  fi
  echo ""
  echo "Then run this script again."
  exit 1
else
  echo "✅ Nix already installed"
fi

# Enable flakes
echo "🔧 Enabling flakes..."
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

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

# Check zsh status (but don't try to change it)
echo ""
echo "🐚 Checking shell status..."
ZSH_PATH=$(command -v zsh)
if [ -n "$ZSH_PATH" ]; then
  if [ "$SHELL" != "$ZSH_PATH" ]; then
    echo "ℹ️  Current shell: $SHELL"
    echo "ℹ️  Zsh installed at: $ZSH_PATH"
    echo ""
    echo "To set zsh as your default shell, run:"
    echo "  chsh -s $ZSH_PATH"
    echo ""
    echo "(You may need to add zsh to /etc/shells first if you get an error)"
  else
    echo "✅ Shell already set to zsh"
  fi
else
  echo "⚠️  Could not find zsh path"
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
