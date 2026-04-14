#!/usr/bin/env bash
set -euo pipefail

# Auto-commit and push dotfile changes to GitHub

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

# Set up SSH for git push (cron doesn't have ssh-agent)
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519 -o IdentitiesOnly=yes"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
cd "$ROOT_DIR"

BRANCH="$(git branch --show-current)"

if [[ -z "$BRANCH" ]]; then
    echo "Could not determine the current git branch"
    exit 1
fi

# Commit any uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    echo "Changes detected, committing..."
    git add -A
    git commit -m "Auto-update: $(date '+%Y-%m-%d %H:%M:%S')"
fi

# Push if there are any unpushed commits (new or previously stranded)
UNPUSHED="$(git log origin/"$BRANCH".."$BRANCH" --oneline 2>/dev/null || true)"
if [[ -n "$UNPUSHED" ]]; then
    echo "Pushing commits to origin/$BRANCH..."
    if git push origin "$BRANCH" 2>&1; then
        echo "Changes pushed to GitHub"
    else
        echo "Failed to push to GitHub"
        exit 1
    fi
else
    echo "Nothing to commit or push"
fi
