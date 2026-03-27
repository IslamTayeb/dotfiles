#!/usr/bin/env bash
set -euo pipefail

# Auto-commit and push dotfile changes to GitHub

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
export GIT_TERMINAL_PROMPT=0
export GH_PROMPT_DISABLED=1

# Set up SSH for git push (cron doesn't have ssh-agent)
export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519 -o IdentitiesOnly=yes"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
cd "$ROOT_DIR"

BRANCH="$(git branch --show-current)"
REMOTE_URL="$(git remote get-url origin)"

if [[ -z "$BRANCH" ]]; then
    echo "❌ Could not determine the current git branch"
    exit 1
fi

PUSH_CMD=(git push origin "$BRANCH")

if [[ "$REMOTE_URL" == https://github.com/* ]] && command -v gh >/dev/null 2>&1; then
    PUSH_CMD=(git -c "credential.helper=!gh auth git-credential" push origin "$BRANCH")
elif [[ "$REMOTE_URL" == https://github.com/* ]]; then
    echo "⚠️ GitHub HTTPS remote detected but gh is unavailable; push may fail"
fi

# Check if there are changes
if [[ -n $(git status --porcelain) ]]; then
    echo "📝 Changes detected, committing..."

    git add -A
    git commit -m "Auto-update: $(date '+%Y-%m-%d %H:%M:%S')"

    echo "🚀 Pushing changes to origin/$BRANCH..."

    if "${PUSH_CMD[@]}"; then
        echo "✅ Changes pushed to GitHub"
    else
        echo "❌ Failed to push to GitHub"
        exit 1
    fi
else
    echo "✨ No changes to commit or push"
fi
