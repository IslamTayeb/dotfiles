#!/usr/bin/env bash
# Auto-commit and push dotfile changes to GitHub

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if there are changes
if [[ -n $(git status -s) ]]; then
    echo "📝 Changes detected, committing..."
    
    git add -A
    git commit -m "Auto-update: $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main
    
    echo "✅ Changes pushed to GitHub"
else
    echo "✨ No changes to commit"
fi
