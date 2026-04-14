#!/usr/bin/env bash
set -euo pipefail

# Auto-pull remote changes and run update

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

# Set up SSH for git pull (cron doesn't have ssh-agent)
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519 -o IdentitiesOnly=yes"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
cd "$ROOT_DIR"

echo "Pulling latest changes..."
if git pull 2>&1; then
    echo "Pull complete"
else
    echo "Failed to pull from GitHub"
    exit 1
fi

echo "Running update..."
"$SCRIPT_DIR/update.sh"
