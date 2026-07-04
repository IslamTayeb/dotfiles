---
name: codex-environment-sync
description: Sync Islam's Codex environment across Mac, resembool, vm-typhon, and future devboxes using the dotfiles repo. Use when adding Codex projects, moving chats/threads between hosts, installing personal skills, updating Codex config.toml profiles, refreshing remote Codex app project config, or debugging missing Codex skills/connections on a machine.
metadata:
  short-description: Sync Codex config, skills, and projects
---

# Codex Environment Sync

Use this skill when the task is about keeping Islam's Codex setup consistent across machines.

## Source Of Truth

- Dotfiles repo: `~/.config/nix-config` on bootstrapped machines, or `/Users/islamtayeb/Documents/GitHub/dotfiles` on the Mac.
- Codex sync script: `scripts/sync-codex.sh`.
- Personal skills live in `configs/codex/skills/`.
- Host config profiles live in `configs/codex/profiles/`.
- Mac Codex app remote-project config lives in `configs/codex/codex-app/config.json`.

Do not sync secrets or transient state:

- Never commit or copy `~/.codex/auth.json`.
- Never commit or copy `~/.codex/state_*.sqlite`, `logs_*.sqlite`, `memories_*.sqlite`, `goals_*.sqlite`, sessions, caches, plugin cache directories, or app-server sockets.
- Treat thread/session migration as a separate explicit operation.

## Standard Workflow

1. Inspect current host state:
   - `find ~/.codex/skills -maxdepth 2 -mindepth 1 -type d`
   - `sed -n '1,220p' ~/.codex/config.toml`
   - For Mac app remote projects: `python3 -m json.tool ~/.codex/codex-app/config.json`
2. Update dotfiles first:
   - Copy personal skill folders into `configs/codex/skills/`.
   - Add or update host profiles under `configs/codex/profiles/`.
   - Add Mac app remote projects in `configs/codex/codex-app/config.json`.
3. Install from dotfiles:
   - Skills only: `scripts/sync-codex.sh --skills-only`
   - Full host profile: `scripts/sync-codex.sh --profile auto --write-config`
   - Mac app project refresh: `scripts/sync-codex.sh --profile macos`, then reopen or refresh the Codex app.
4. For remote hosts, copy/pull dotfiles first, then run the sync script on that host.
5. Validate:
   - `codex doctor --summary`
   - `codex remote-control start --json` when the host should be phone/app reachable.
   - `codex_app.list_projects` from the Mac app when remote project visibility matters.

## Resembool Migration Cleanup

When moving a project off `resembool`, update all three layers:

1. Remove the project from `configs/codex/codex-app/config.json` and `configs/codex/profiles/resembool.toml`.
2. Add it to the target host profile and Mac app config, usually `vm-typhon` for Typhon/Hydra projects.
3. On the Mac, run `scripts/sync-codex.sh --profile macos`. The script reconciles `~/.codex/.codex-global-state.json` so stale saved remote projects such as old `codex-devbox` or removed `resembool` paths do not keep appearing in the app.

If the project still appears after the Mac app config is reconciled, check for active remote threads on `resembool`:

```bash
ssh resembool 'sqlite3 -header -column ~/.codex/state_5.sqlite "select archived,cwd,count(*) n,max(datetime(updated_at, '\''unixepoch'\'')) latest from threads group by archived,cwd order by cwd,archived;"'
```

Archive only the moved project's old `resembool` threads, and move their rollout files from `~/.codex/sessions` to `~/.codex/archived_sessions` so `codex doctor --summary` still reports matching state.

## Current Host Intent

- Mac: full desktop config plus personal skills and Codex app remote-project config.
- `resembool`: general always-on Codex host. Projects under `/work/projects`, including Mapperatorinator, alembic-dev, personal-website, obsidian-vault, and resume. Do not use it for Typhon/Hydra dev.
- `vm-typhon`: Typhon/Hydra-focused host. Keep `hydra-dev` under `/home/islam/hydra-dev` and Typhon under `/home/islam/typhon`, and install the same personal skills and base Codex config.

## Common Failure Modes

- If Codex app SSH says it cannot execute a command-line and remote command, remove `RemoteCommand` from `~/.ssh/config`. Put tmux auto-attach in remote interactive shell startup instead.
- If a remote project has no chats, verify the remote daemon's `threads.cwd` matches the saved remote project path exactly.
- If a host has only `.system` skills, run the sync script from dotfiles and restart Codex.
