#!/usr/bin/env bash
set -e

echo "🔄 Updating Nix dotfiles..."

# Get script directory (go to parent of scripts dir)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

# Update flake inputs
echo "📦 Updating flake inputs..."
nix flake update

# Detect config name
USERNAME=$(whoami)
HOSTNAME=$(hostname -s)
CONFIG_NAME="${USERNAME}@${HOSTNAME}"

# Rebuild and switch
echo "🏗️  Rebuilding configuration..."
nix run home-manager/master -- switch --flake ".#${CONFIG_NAME}"

echo "✅ Update complete!"
