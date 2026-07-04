#!/usr/bin/env bash
set -e

echo "🚀 Setting up Nix dotfiles..."

# Get the directory where this script is located (go to parent of scripts dir)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$SCRIPT_DIR"

# Make Nix available when the script is run from a non-login SSH shell.
if ! command -v nix >/dev/null 2>&1; then
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
fi

if ! command -v nix >/dev/null 2>&1; then
  echo "❌ Nix is not available in PATH. Install Nix or source its profile first."
  exit 1
fi

# home.nix links config files through this stable path.
CONFIG_DIR="$HOME/.config/nix-config"
if [ "$SCRIPT_DIR" != "$CONFIG_DIR" ]; then
  mkdir -p "$HOME/.config"
  if [ -L "$CONFIG_DIR" ] || [ ! -e "$CONFIG_DIR" ]; then
    ln -sfn "$SCRIPT_DIR" "$CONFIG_DIR"
  elif [ ! -d "$CONFIG_DIR" ] || [ "$(cd "$CONFIG_DIR" && pwd -P)" != "$SCRIPT_DIR" ]; then
    echo "⚠️  $CONFIG_DIR exists and does not point to $SCRIPT_DIR"
    echo "   Home Manager config symlinks may not resolve correctly."
  fi
fi

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

echo "🖥️  Installing terminal definitions..."
if [ -f "$SCRIPT_DIR/configs/terminfo/xterm-ghostty.terminfo" ]; then
  if command -v tic >/dev/null 2>&1; then
    mkdir -p "$HOME/.terminfo"
    if ! tic -x -o "$HOME/.terminfo" "$SCRIPT_DIR/configs/terminfo/xterm-ghostty.terminfo"; then
      echo "⚠️  Could not compile Ghostty terminfo; continuing dotfiles install."
    fi
  else
    echo "⚠️  tic is not available; skipping Ghostty terminfo install."
  fi
fi

echo "🤖 Syncing Codex config and personal skills..."
bash "$SCRIPT_DIR/scripts/sync-codex.sh" --profile auto --write-config || echo "⚠️  Codex sync failed; continuing dotfiles install."

# Auto-install tmux plugins
echo "🔌 Installing tmux plugins..."
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  TMUX_BIN="$(command -v tmux || true)"
  if [ -z "$TMUX_BIN" ] && [ -x "$HOME/.nix-profile/bin/tmux" ]; then
    TMUX_BIN="$HOME/.nix-profile/bin/tmux"
  fi
  if [ -z "$TMUX_BIN" ] && [ -x "/etc/profiles/per-user/$USER/bin/tmux" ]; then
    TMUX_BIN="/etc/profiles/per-user/$USER/bin/tmux"
  fi
  if [ -z "$TMUX_BIN" ] && [ -x "/nix/var/nix/profiles/per-user/$USER/profile/bin/tmux" ]; then
    TMUX_BIN="/nix/var/nix/profiles/per-user/$USER/profile/bin/tmux"
  fi

  if [ -n "$TMUX_BIN" ]; then
    export PATH="${TMUX_BIN%/*}:$PATH"
    "$TMUX_BIN" start-server \; set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins"
    bash "$HOME/.tmux/plugins/tpm/bin/install_plugins"
  else
    echo "⚠️  tmux is not available; skipping tmux plugin install."
  fi
fi

echo ""
echo "✨ Setup complete!"
echo ""

# Prefer zsh as the login shell. Linux setup should be useful on first SSH
# without an interactive prompt, so try non-interactive changes first.
ZSH_PATH="$(command -v zsh || true)"
LOGIN_SHELL="$(getent passwd "$USER" 2>/dev/null | awk -F: '{print $7}' || true)"
IS_INTERACTIVE=false
if [ -t 0 ] && [ -t 1 ]; then
  IS_INTERACTIVE=true
fi

set_login_shell_to_zsh() {
  if [ -z "$ZSH_PATH" ]; then
    echo "⚠️  zsh is not installed or not in PATH; leaving login shell unchanged."
    return 1
  fi

  if [ "$LOGIN_SHELL" = "$ZSH_PATH" ]; then
    echo "✅ Login shell already set to zsh"
    return 0
  fi

  echo "🐚 Setting zsh as default shell..."

  if chsh -s "$ZSH_PATH" "$USER" </dev/null 2>/dev/null || chsh -s "$ZSH_PATH" </dev/null 2>/dev/null; then
    echo "✅ Default shell changed to zsh"
    return 0
  fi

  if command -v sudo >/dev/null 2>&1 && sudo -n chsh -s "$ZSH_PATH" "$USER" 2>/dev/null; then
    echo "✅ Default shell changed to zsh with sudo"
    return 0
  fi

  echo "⚠️  Could not change the login shell automatically."
  echo "   Run this manually if needed: chsh -s $ZSH_PATH"
  return 1
}

if [[ "$SYSTEM" == *linux ]]; then
  if set_login_shell_to_zsh; then
    SWITCH_TO_ZSH=true
  else
    SWITCH_TO_ZSH=false
  fi
elif [ -n "$ZSH_PATH" ] && [ "$LOGIN_SHELL" = "$ZSH_PATH" ]; then
  echo "✅ Login shell already set to zsh"
  SWITCH_TO_ZSH=true
elif [ "$IS_INTERACTIVE" = true ]; then
  echo "🐚 Your current login shell is: ${LOGIN_SHELL:-$SHELL}"
  read -p "Would you like to set zsh as your default shell? (y/N) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]] && set_login_shell_to_zsh; then
    SWITCH_TO_ZSH=true
  else
    echo "ℹ️  Keeping current shell. You can always use zsh by typing 'zsh'"
    SWITCH_TO_ZSH=false
  fi
else
  echo "ℹ️  Non-interactive non-Linux install; leaving login shell unchanged."
  SWITCH_TO_ZSH=false
fi

echo ""
echo "Next steps:"
echo "  - Open nvim to let LazyVim install plugins"
echo "  - Run 'tmux' (prefix is Ctrl-b over SSH, Ctrl-l locally)"
echo "  - Update later with: ./scripts/update.sh"
echo ""

# Only exec zsh for an actual interactive terminal. Non-interactive installs
# should finish cleanly so bootstrap/CI/SSH provisioning can continue.
if [ "$SWITCH_TO_ZSH" = true ]; then
  if [ "$IS_INTERACTIVE" = true ]; then
    echo "Starting zsh..."
    sleep 1
    exec zsh -l
  else
    echo "zsh will be used on the next login/session."
  fi
fi
