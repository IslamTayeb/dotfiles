#!/usr/bin/env bash
set -euo pipefail

# Auto-commit and push dotfile changes to GitHub

# Set up SSH for git push (cron doesn't have ssh-agent)
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519 -o IdentitiesOnly=yes"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
cd "$ROOT_DIR"

BRANCH="$(git branch --show-current)"

if [[ -z "$BRANCH" ]]; then
    echo "❌ Could not determine the current git branch"
    exit 1
fi

# Check if there are changes
if [[ -n $(git status --porcelain) ]]; then
    echo "📝 Changes detected, committing..."

    git add -A
    git commit -m "Auto-update: $(date '+%Y-%m-%d %H:%M:%S')"

    echo "🚀 Pushing changes to origin/$BRANCH..."

    if git push origin "$BRANCH"; then
        echo "✅ Changes pushed to GitHub"
    else
        echo "❌ Failed to push to GitHub"
        exit 1
    fi
else
    echo "✨ No changes to commit or push"
fi
