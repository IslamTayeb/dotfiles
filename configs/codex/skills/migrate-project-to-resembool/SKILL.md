---
name: migrate-project-to-resembool
description: Migrate a local project or working directory to Islam's resembool devbox with rsync, including ignored/untracked local files such as .env files, GitHub cleanliness checks for tracked Git state, selected Codex project chats and goal rows, remote environment setup, and smoke-test verification. Use when Codex is asked to move, copy, port, migrate, or resume a full project/worktree from the Mac to resembool, especially when Git alone is insufficient because local secrets, ignored state, or Codex chats must move too.
---

# Migrate Project To Resembool

Use this skill to move a project from the Mac to `resembool` as a usable remote Codex project. The transfer is not a Git clone: it uses `rsync` so local ignored/untracked state can move too, while still requiring tracked Git state to be clean and pushed when the project has a GitHub remote.

## Default Workflow

1. Identify the local project root and remote name. Default destination is `resembool:/work/projects/<basename>`.
2. Run the helper in dry-run mode first:

   ```bash
   python3 ~/.codex/skills/migrate-project-to-resembool/scripts/migrate_project_to_resembool.py /path/to/project
   ```

3. Review the dry-run report:
   - destination exists check
   - GitHub clean/pushed status
   - selected Codex thread count
   - selected goal count
   - rsync include/exclude summary
4. Fix any fail-loud blockers before executing. For GitHub repos, tracked changes must be committed and pushed. Keep `.env*` and ignored local state uncommitted.
5. Execute only after the dry-run is clean:

   ```bash
   python3 ~/.codex/skills/migrate-project-to-resembool/scripts/migrate_project_to_resembool.py /path/to/project --execute
   ```

6. On `resembool`, set up the Linux environment from repo manifests or project docs. Do not rely on copied Mac dependency directories; the helper excludes common OS-specific generated dirs by default.
7. Run a project-specific smoke test before reporting success.

## Helper Behavior

The helper script:

- copies to `resembool:/work/projects/.migrations/<name>-<timestamp>` first, then renames to `/work/projects/<name>` after rsync succeeds
- fails if `/work/projects/<name>` already exists
- uses `rsync`, not Git, for project files
- copies `.git`, source, data, notes, local configs, untracked files, ignored files, and `.env*`
- excludes generated Mac/Linux-risky dirs by default: `.venv/`, `venv/`, `node_modules/`, `__pycache__/`, `.pytest_cache/`, `.ruff_cache/`, `.mypy_cache/`, `.next/`, `dist/`, `build/`, `target/`, `.DS_Store`, `._*`, `.AppleDouble/`
- selects Codex threads from local `~/.codex/state_5.sqlite` whose `cwd` exactly matches the local project root
- copies only those rollout JSONL files under `~/.codex/sessions`
- imports matching thread rows into remote `~/.codex/state_5.sqlite`, rewriting `cwd` and `rollout_path`
- updates remote `~/.codex/session_index.jsonl` for migrated thread IDs
- imports matching `thread_goals` rows only when a source `~/.codex/goals_*.sqlite` exists
- never copies Codex `auth.json`, whole state DBs, logs DBs, plugin caches, app-server sockets, or unrelated sessions

## GitHub Rule

For a Git repo with a GitHub remote:

- require an upstream branch
- run `git fetch`
- fail if tracked/staged changes remain
- fail if the branch is ahead of, behind, or diverged from upstream
- fail if tracked changes include `.env`, private keys, token, credential, or secret-looking paths

If the user explicitly wants Codex to checkpoint tracked changes first, inspect `git status`, verify no tracked secret-looking paths are involved, then use the helper's explicit `--checkpoint-tracked` flag. Do not commit ignored/untracked `.env*` files.

## Remote Environment Setup

After `--execute`, SSH to `resembool` and set up the environment from the remote project:

- Python: prefer `uv`, `pyproject.toml`, `requirements*.txt`, or project docs.
- Node: use the lockfile-selected package manager.
- Other stacks: follow `AGENTS.md`, README, Makefile, package scripts, or repo-specific docs.

Run the smallest meaningful smoke test available. At minimum check:

```bash
ssh resembool 'cd /work/projects/<name> && git status --short && git remote -v'
ssh resembool 'codex doctor --summary'
ssh resembool 'sqlite3 -header -column ~/.codex/state_5.sqlite "select cwd, count(*) from threads where cwd = '\''/work/projects/<name>'\'' group by cwd;"'
```

Prefer a repo-specific import/build/test command when cheap. If no project test exists, say that clearly and report the closest smoke check used.

## Final Report

Do not say the migration is done until the helper has executed, the remote environment has been set up or intentionally deemed unnecessary, and smoke checks have passed. Report:

- remote copied path
- GitHub cleanliness status
- environment setup commands run
- smoke test command and result
- migrated thread count
- migrated goal count, or "no source goals DB"
- excluded generated dirs
- manual follow-up, if any
