#!/usr/bin/env bash
set -euo pipefail

# Auto-pull remote changes and run update

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
export GIT_TERMINAL_PROMPT=0
export GH_PROMPT_DISABLED=1

# Load GitHub token for cron (keychain is not available in cron)
TOKEN_FILE="$HOME/.gh_cron_token"
if [[ -f "$TOKEN_FILE" ]]; then
    export GH_TOKEN="$(cat "$TOKEN_FILE")"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
cd "$ROOT_DIR"

REMOTE_URL="$(git remote get-url origin)"

GIT_PULL_ARGS=()
if [[ "$REMOTE_URL" == https://github.com/* ]] && command -v gh >/dev/null 2>&1; then
    GIT_PULL_ARGS=(-c "credential.helper=!gh auth git-credential")
fi

echo "Pulling latest changes..."
if git "${GIT_PULL_ARGS[@]}" pull 2>&1; then
    echo "Pull complete"
else
    echo "Failed to pull from GitHub"
    exit 1
fi

echo "Running update..."
"$SCRIPT_DIR/update.sh"
