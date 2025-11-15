#!/usr/bin/env bash
# Setup automatic updates via cron

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cron job to pull and update every hour
CRON_JOB="0 * * * * cd $SCRIPT_DIR && git pull && ./update.sh >> $SCRIPT_DIR/auto-update.log 2>&1"

# Cron job to auto-commit changes every 30 minutes
COMMIT_JOB="*/30 * * * * cd $SCRIPT_DIR && ./auto-commit.sh >> $SCRIPT_DIR/auto-commit.log 2>&1"

echo "Setting up cron jobs..."

# Add cron jobs if they don't exist
(crontab -l 2>/dev/null | grep -v "$SCRIPT_DIR/update.sh"; echo "$CRON_JOB") | crontab -
(crontab -l 2>/dev/null | grep -v "$SCRIPT_DIR/auto-commit.sh"; echo "$COMMIT_JOB") | crontab -

echo "✅ Cron jobs installed:"
echo "  - Pull & update: Every hour"
echo "  - Auto-commit: Every 30 minutes"
echo ""
echo "Logs will be written to:"
echo "  - $SCRIPT_DIR/auto-update.log"
echo "  - $SCRIPT_DIR/auto-commit.log"
echo ""
echo "To remove cron jobs:"
echo "  crontab -e"
