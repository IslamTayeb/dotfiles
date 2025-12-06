#!/usr/bin/env bash
# Auto-commit and push dotfile changes to GitHub

# Set up SSH for git push (cron doesn't have ssh-agent)
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519 -o IdentitiesOnly=yes"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Check if there are changes
if [[ -n $(git status -s) ]]; then
    echo "📝 Changes detected, committing..."

    git add -A
    git commit -m "Auto-update: $(date '+%Y-%m-%d %H:%M:%S')"

    if git push origin main; then
        echo "✅ Changes pushed to GitHub"
    else
        echo "❌ Failed to push to GitHub (exit code: $?)"
        exit 1
    fi
else
    echo "✨ No changes to commit"
fi
