#!/usr/bin/env bash
# Setup automatic updates via cron

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

mkdir -p "$ROOT_DIR/logs"

# Cron job to pull and update every hour (uses auto-pull.sh for proper credentials + PATH)
CRON_JOB="0 * * * * $SCRIPT_DIR/auto-pull.sh >> $ROOT_DIR/logs/auto-update.log 2>&1"

# Cron job to auto-commit and push changes every 30 minutes
COMMIT_JOB="*/30 * * * * $SCRIPT_DIR/auto-commit.sh >> $ROOT_DIR/logs/auto-commit.log 2>&1"

echo "Setting up cron jobs..."

# Remove old entries and add new ones
EXISTING=$(crontab -l 2>/dev/null | grep -v "auto-commit.sh" | grep -v "auto-pull.sh" | grep -v "update.sh" || true)
echo "$EXISTING
$CRON_JOB
$COMMIT_JOB" | grep -v '^$' | crontab -

echo "Cron jobs installed:"
echo "  - Pull & update: Every hour (auto-pull.sh)"
echo "  - Auto-commit + push: Every 30 minutes (auto-commit.sh)"
echo ""
echo "Logs:"
echo "  - $ROOT_DIR/logs/auto-update.log"
echo "  - $ROOT_DIR/logs/auto-commit.log"
echo ""
echo "Prerequisites:"
echo "  - gh auth login (run once interactively)"
echo "  - gh auth token > ~/.gh_cron_token && chmod 600 ~/.gh_cron_token"
echo ""
echo "To remove: crontab -e"
