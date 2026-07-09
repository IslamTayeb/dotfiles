#!/usr/bin/env python3
"""Migrate a local project and matching Codex state to resembool."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import pathlib
import re
import shlex
import shutil
import sqlite3
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from typing import Any


DEFAULT_EXCLUDES = [
    ".venv/",
    "venv/",
    "node_modules/",
    "__pycache__/",
    ".pytest_cache/",
    ".ruff_cache/",
    ".mypy_cache/",
    ".next/",
    "dist/",
    "build/",
    "target/",
    ".DS_Store",
    "._*",
    ".AppleDouble/",
]

SECRET_PATH_RE = re.compile(
    r"(^|/)(\.env($|\.)|.*secret.*|.*credential.*|.*token.*|id_rsa($|\.)|.*\.(pem|key|p12|pfx)$)",
    re.IGNORECASE,
)


class MigrationError(RuntimeError):
    pass


@dataclass
class RunResult:
    args: list[str]
    stdout: str
    stderr: str
    returncode: int


def run(
    args: list[str],
    *,
    cwd: pathlib.Path | None = None,
    check: bool = True,
    input_text: str | None = None,
) -> RunResult:
    proc = subprocess.run(
        args,
        cwd=str(cwd) if cwd else None,
        text=True,
        input=input_text,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    result = RunResult(args=args, stdout=proc.stdout, stderr=proc.stderr, returncode=proc.returncode)
    if check and proc.returncode != 0:
        command = " ".join(shlex.quote(a) for a in args)
        raise MigrationError(
            f"Command failed ({proc.returncode}): {command}\nSTDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}"
        )
    return result


def ssh(host: str, command: str, *, check: bool = True, input_text: str | None = None) -> RunResult:
    return run(["ssh", host, command], check=check, input_text=input_text)


def iso_now_compact() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def utc_iso_from_epoch(value: Any) -> str:
    try:
        timestamp = int(value)
    except (TypeError, ValueError):
        timestamp = 0
    return dt.datetime.fromtimestamp(timestamp, dt.timezone.utc).isoformat().replace("+00:00", "Z")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Migrate a local project and matching Codex chats/goals to resembool.",
    )
    parser.add_argument("project", help="Local project directory to migrate.")
    parser.add_argument("--host", default="resembool", help="SSH host alias. Defaults to resembool.")
    parser.add_argument("--name", help="Remote project directory name. Defaults to local basename.")
    parser.add_argument("--remote-root", default="/work/projects", help="Remote projects root.")
    parser.add_argument("--codex-home", default=os.path.expanduser("~/.codex"), help="Local Codex home.")
    parser.add_argument("--remote-codex-home", default="~/.codex", help="Remote Codex home.")
    parser.add_argument("--execute", action="store_true", help="Actually transfer files and import Codex state.")
    parser.add_argument(
        "--checkpoint-tracked",
        action="store_true",
        help="When combined with --execute, commit and push non-secret tracked changes before migration.",
    )
    parser.add_argument(
        "--skip-github-check",
        action="store_true",
        help="Skip GitHub clean/upstream checks. Use only for non-GitHub or test migrations.",
    )
    parser.add_argument(
        "--no-remote-check",
        action="store_true",
        help="Skip SSH destination existence check. Intended for local dry-run tests only.",
    )
    parser.add_argument("--no-codex", action="store_true", help="Skip Codex thread/goal migration.")
    parser.add_argument("--smoke-command", help="Optional remote smoke command run after execute.")
    parser.add_argument("--list-files", action="store_true", help="Print dry-run rsync file list.")
    return parser.parse_args()


def ensure_project(path_text: str) -> pathlib.Path:
    project = pathlib.Path(path_text).expanduser().resolve()
    if not project.exists():
        raise MigrationError(f"Project path does not exist: {project}")
    if not project.is_dir():
        raise MigrationError(f"Project path is not a directory: {project}")
    return project


def git(project: pathlib.Path, args: list[str], *, check: bool = True) -> RunResult:
    return run(["git", *args], cwd=project, check=check)


def is_git_repo(project: pathlib.Path) -> bool:
    return git(project, ["rev-parse", "--is-inside-work-tree"], check=False).stdout.strip() == "true"


def github_remotes(project: pathlib.Path) -> list[str]:
    result = git(project, ["remote", "-v"], check=False)
    if result.returncode != 0:
        return []
    return [line for line in result.stdout.splitlines() if "github.com" in line.lower()]


def tracked_dirty_paths(project: pathlib.Path) -> list[str]:
    paths: set[str] = set()
    for args in (["diff", "--name-only"], ["diff", "--cached", "--name-only"], ["ls-files", "-m", "-d"]):
        result = git(project, args, check=True)
        paths.update(line for line in result.stdout.splitlines() if line)
    return sorted(paths)


def assert_no_secret_tracked_paths(paths: list[str]) -> None:
    secret_paths = [path for path in paths if SECRET_PATH_RE.search(path)]
    if secret_paths:
        joined = "\n".join(f"  - {path}" for path in secret_paths)
        raise MigrationError(f"Refusing to commit or migrate tracked secret-looking paths:\n{joined}")


def check_github_state(project: pathlib.Path, *, execute: bool, checkpoint_tracked: bool) -> dict[str, Any]:
    report: dict[str, Any] = {
        "is_git_repo": is_git_repo(project),
        "github_remote": False,
        "checked": False,
        "checkpoint_commit": None,
        "status": "not a git repo",
    }
    if not report["is_git_repo"]:
        return report

    remotes = github_remotes(project)
    report["github_remote"] = bool(remotes)
    if not remotes:
        report["status"] = "git repo without GitHub remote; GitHub clean check not required"
        return report

    report["checked"] = True
    report["remote_lines"] = remotes
    git(project, ["fetch", "--all", "--prune"])

    dirty = tracked_dirty_paths(project)
    assert_no_secret_tracked_paths(dirty)
    if dirty and checkpoint_tracked:
        if not execute:
            raise MigrationError("--checkpoint-tracked requires --execute")
        git(project, ["add", "-u"])
        staged = git(project, ["diff", "--cached", "--name-only"]).stdout.splitlines()
        assert_no_secret_tracked_paths(staged)
        if staged:
            git(project, ["commit", "-m", "chore: checkpoint before resembool migration"])
            report["checkpoint_commit"] = git(project, ["rev-parse", "--short", "HEAD"]).stdout.strip()
            git(project, ["push"])
    elif dirty:
        joined = "\n".join(f"  - {path}" for path in dirty)
        raise MigrationError(
            "Tracked/staged Git changes must be committed and pushed before migration.\n"
            "Ignored/untracked .env files can remain uncommitted and will be rsynced.\n"
            f"Tracked dirty paths:\n{joined}"
        )

    remaining = git(project, ["status", "--porcelain=v1", "--untracked-files=no"]).stdout.strip()
    if remaining:
        raise MigrationError(f"Tracked Git state is still dirty after checkpoint handling:\n{remaining}")

    upstream = git(project, ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"], check=False)
    if upstream.returncode != 0:
        raise MigrationError("GitHub repo has no upstream branch; set upstream and push before migration.")
    report["upstream"] = upstream.stdout.strip()

    counts = git(project, ["rev-list", "--left-right", "--count", "HEAD...@{u}"]).stdout.split()
    ahead, behind = int(counts[0]), int(counts[1])
    report["ahead"] = ahead
    report["behind"] = behind
    if ahead or behind:
        raise MigrationError(
            f"Branch is not clean against {report['upstream']}: ahead={ahead}, behind={behind}. "
            "Push/pull/rebase before migration."
        )

    report["status"] = f"clean and pushed to {report['upstream']}"
    return report


def local_rsync_file_list(project: pathlib.Path) -> list[str]:
    with tempfile.TemporaryDirectory(prefix="resembool-rsync-dry-run-") as tmp:
        cmd = ["rsync", "-an", "--out-format=%n"]
        for pattern in DEFAULT_EXCLUDES:
            cmd.extend(["--exclude", pattern])
        cmd.extend([f"{project}/", f"{tmp}/"])
        result = run(cmd)
    return [line for line in result.stdout.splitlines() if line]


def remote_home(host: str) -> str:
    result = ssh(host, 'printf "%s" "$HOME"')
    home = result.stdout.strip()
    if not home.startswith("/"):
        raise MigrationError(f"Could not determine absolute remote home for {host}: {home!r}")
    return home


def expand_remote_codex_home(remote_codex_home: str, home: str) -> str:
    if remote_codex_home == "~/.codex":
        return f"{home}/.codex"
    if remote_codex_home.startswith("~/"):
        return f"{home}/{remote_codex_home[2:]}"
    return remote_codex_home


def check_remote_destination(host: str, remote_path: str, stage_path: str) -> None:
    command = (
        f"if [ -e {shlex.quote(remote_path)} ]; then "
        f"echo 'remote destination already exists: {remote_path}' >&2; exit 20; fi; "
        f"if [ -e {shlex.quote(stage_path)} ]; then "
        f"echo 'remote staging path already exists: {stage_path}' >&2; exit 21; fi"
    )
    ssh(host, command)


def source_threads(codex_home: pathlib.Path, project: pathlib.Path, remote_path: str, remote_codex_home: str) -> dict[str, Any]:
    state_db = codex_home / "state_5.sqlite"
    if not state_db.exists():
        raise MigrationError(f"Local Codex state DB not found: {state_db}")

    conn = sqlite3.connect(state_db)
    conn.row_factory = sqlite3.Row
    rows = [dict(row) for row in conn.execute("select * from threads where cwd = ? order by updated_at desc", (str(project),))]
    conn.close()

    session_entries = read_session_index(codex_home / "session_index.jsonl")
    index_by_id = {entry.get("id"): entry for entry in session_entries if entry.get("id")}
    payload_rows = []
    rollout_pairs = []
    index_updates = []

    for row in rows:
        local_rollout = pathlib.Path(row["rollout_path"]).expanduser()
        if not local_rollout.exists():
            raise MigrationError(f"Rollout file for thread {row['id']} is missing: {local_rollout}")
        try:
            rel = local_rollout.resolve().relative_to(codex_home.resolve())
        except ValueError as exc:
            raise MigrationError(f"Rollout path is outside Codex home and will not be copied: {local_rollout}") from exc
        remote_rollout = pathlib.PurePosixPath(remote_codex_home) / rel.as_posix()
        row["cwd"] = remote_path
        row["rollout_path"] = str(remote_rollout)
        payload_rows.append(row)
        rollout_pairs.append((str(local_rollout), str(remote_rollout)))

        index_entry = index_by_id.get(row["id"])
        if index_entry:
            index_updates.append(index_entry)
        else:
            index_updates.append(
                {
                    "id": row["id"],
                    "thread_name": row.get("title") or row["id"],
                    "updated_at": utc_iso_from_epoch(row.get("updated_at")),
                }
            )

    goals = source_goals(codex_home, [row["id"] for row in rows])
    return {
        "threads": payload_rows,
        "rollout_pairs": rollout_pairs,
        "session_index_updates": index_updates,
        "goals": goals,
        "source_state_db": str(state_db),
    }


def read_session_index(path: pathlib.Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    entries = []
    for line in path.read_text().splitlines():
        if not line.strip():
            continue
        try:
            entries.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return entries


def source_goals(codex_home: pathlib.Path, thread_ids: list[str]) -> dict[str, Any]:
    if not thread_ids:
        return {"source_goals_db": None, "rows": []}
    placeholders = ",".join("?" for _ in thread_ids)
    for db in sorted(codex_home.glob("goals_*.sqlite")):
        conn = sqlite3.connect(db)
        conn.row_factory = sqlite3.Row
        try:
            table = conn.execute(
                "select name from sqlite_master where type = 'table' and name = 'thread_goals'"
            ).fetchone()
            if not table:
                continue
            rows = [
                dict(row)
                for row in conn.execute(
                    f"select * from thread_goals where thread_id in ({placeholders})",
                    thread_ids,
                )
            ]
            return {"source_goals_db": str(db), "rows": rows}
        finally:
            conn.close()
    return {"source_goals_db": None, "rows": []}


REMOTE_IMPORT_SCRIPT = r'''
import json
import os
import pathlib
import shutil
import sqlite3
import sys

payload_path = pathlib.Path(sys.argv[1])
payload = json.loads(payload_path.read_text())
codex_home = pathlib.Path(payload["remote_codex_home"]).expanduser()
state_db = codex_home / "state_5.sqlite"
if not state_db.exists():
    raise SystemExit(f"remote Codex state DB not found: {state_db}")

def backup_sqlite(db_path, label):
    backup_path = db_path.with_name(f"{db_path.name}.backup.{label}")
    src = sqlite3.connect(db_path)
    dst = sqlite3.connect(backup_path)
    try:
        src.backup(dst)
    finally:
        dst.close()
        src.close()
    return str(backup_path)

def table_columns(conn, table):
    return [row[1] for row in conn.execute(f"pragma table_info({table})")]

def incoming_time(row):
    value = row.get("updated_at_ms")
    if value is not None:
        return int(value)
    return int(row.get("updated_at") or 0) * 1000

label = payload["label"]
state_backup = backup_sqlite(state_db, label)
conn = sqlite3.connect(state_db)
conn.row_factory = sqlite3.Row
thread_cols = table_columns(conn, "threads")
thread_ids = []
try:
    for row in payload["threads"]:
        thread_ids.append(row["id"])
        existing = conn.execute("select updated_at, updated_at_ms from threads where id = ?", (row["id"],)).fetchone()
        if existing:
            existing_ms = existing["updated_at_ms"] if "updated_at_ms" in existing.keys() and existing["updated_at_ms"] is not None else existing["updated_at"] * 1000
            if existing_ms > incoming_time(row):
                raise SystemExit(f"remote thread is newer than incoming thread: {row['id']}")
        cols = [col for col in thread_cols if col in row]
        placeholders = ", ".join("?" for _ in cols)
        updates = ", ".join(f"{col} = excluded.{col}" for col in cols if col != "id")
        sql = f"insert into threads ({', '.join(cols)}) values ({placeholders}) on conflict(id) do update set {updates}"
        conn.execute(sql, [row[col] for col in cols])
    conn.commit()
finally:
    conn.close()

index_path = codex_home / "session_index.jsonl"
existing_entries = []
if index_path.exists():
    for line in index_path.read_text().splitlines():
        if not line.strip():
            continue
        try:
            existing_entries.append(json.loads(line))
        except json.JSONDecodeError:
            existing_entries.append({"_raw": line})

updates = {entry["id"]: entry for entry in payload["session_index_updates"] if entry.get("id")}
seen = set()
merged = []
for entry in existing_entries:
    entry_id = entry.get("id")
    if entry_id in updates:
        merged.append(updates[entry_id])
        seen.add(entry_id)
    elif "_raw" in entry:
        merged.append(entry["_raw"])
    else:
        merged.append(entry)
for entry_id, entry in updates.items():
    if entry_id not in seen:
        merged.append(entry)
tmp_index = index_path.with_suffix(".jsonl.tmp")
with tmp_index.open("w") as fh:
    for entry in merged:
        if isinstance(entry, str):
            fh.write(entry + "\n")
        else:
            fh.write(json.dumps(entry, separators=(",", ":")) + "\n")
tmp_index.replace(index_path)

goals_report = {"source_goals_db": payload["goals"]["source_goals_db"], "imported": 0, "backup": None}
goal_rows = payload["goals"]["rows"]
if goal_rows:
    candidates = sorted(codex_home.glob("goals_*.sqlite"))
    if not candidates:
        raise SystemExit("incoming goal rows exist but no remote goals_*.sqlite DB was found")
    goals_db = candidates[0]
    goals_report["backup"] = backup_sqlite(goals_db, label)
    gconn = sqlite3.connect(goals_db)
    gconn.row_factory = sqlite3.Row
    try:
        goal_cols = table_columns(gconn, "thread_goals")
        for row in goal_rows:
            existing = gconn.execute("select updated_at_ms from thread_goals where thread_id = ?", (row["thread_id"],)).fetchone()
            if existing and int(existing["updated_at_ms"]) > int(row["updated_at_ms"]):
                raise SystemExit(f"remote goal is newer than incoming goal: {row['thread_id']}")
            cols = [col for col in goal_cols if col in row]
            placeholders = ", ".join("?" for _ in cols)
            updates = ", ".join(f"{col} = excluded.{col}" for col in cols if col != "thread_id")
            sql = f"insert into thread_goals ({', '.join(cols)}) values ({placeholders}) on conflict(thread_id) do update set {updates}"
            gconn.execute(sql, [row[col] for col in cols])
            goals_report["imported"] += 1
        gconn.commit()
    finally:
        gconn.close()

print(json.dumps({
    "threads_imported": len(payload["threads"]),
    "goals": goals_report,
    "state_backup": state_backup,
    "thread_ids": thread_ids,
}, indent=2))
'''


def copy_rollouts(host: str, rollout_pairs: list[tuple[str, str]]) -> None:
    parents = sorted({str(pathlib.PurePosixPath(remote).parent) for _, remote in rollout_pairs})
    if parents:
        mkdirs = " ".join(shlex.quote(parent) for parent in parents)
        ssh(host, f"mkdir -p {mkdirs}")
    for local, remote in rollout_pairs:
        remote_parent = str(pathlib.PurePosixPath(remote).parent)
        run(["rsync", "-a", local, f"{host}:{remote_parent}/"])


def import_codex_payload(host: str, payload: dict[str, Any], remote_codex_home: str, label: str) -> dict[str, Any]:
    payload = dict(payload)
    payload["remote_codex_home"] = remote_codex_home
    payload["label"] = label
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as fh:
        json.dump(payload, fh)
        local_payload = pathlib.Path(fh.name)
    try:
        remote_payload = f"{remote_codex_home}/migration-payload-{label}.json"
        ssh(host, f"mkdir -p {shlex.quote(remote_codex_home)}")
        run(["rsync", "-a", str(local_payload), f"{host}:{remote_payload}"])
        result = ssh(host, f"python3 - {shlex.quote(remote_payload)}", input_text=REMOTE_IMPORT_SCRIPT)
        ssh(host, f"rm -f {shlex.quote(remote_payload)}", check=False)
        return json.loads(result.stdout)
    finally:
        local_payload.unlink(missing_ok=True)


def execute_project_rsync(project: pathlib.Path, host: str, remote_path: str, stage_path: str) -> None:
    stage_parent = str(pathlib.PurePosixPath(stage_path).parent)
    remote_root = str(pathlib.PurePosixPath(remote_path).parent)
    ssh(host, f"mkdir -p {shlex.quote(stage_parent)} {shlex.quote(remote_root)}")
    cmd = ["rsync", "-aH"]
    for pattern in DEFAULT_EXCLUDES:
        cmd.extend(["--exclude", pattern])
    cmd.extend([f"{project}/", f"{host}:{stage_path}/"])
    run(cmd)
    ssh(
        host,
        f"test ! -e {shlex.quote(remote_path)} && mv {shlex.quote(stage_path)} {shlex.quote(remote_path)}",
    )


def smoke(host: str, remote_path: str, smoke_command: str | None) -> dict[str, Any]:
    checks: dict[str, Any] = {}
    git_check = ssh(
        host,
        f"cd {shlex.quote(remote_path)} && "
        "(git status --short && git remote -v) 2>&1 || true",
    )
    checks["git"] = git_check.stdout.strip()
    doctor = ssh(host, "codex doctor --summary", check=False)
    checks["codex_doctor_returncode"] = doctor.returncode
    checks["codex_doctor_tail"] = "\n".join((doctor.stdout + doctor.stderr).splitlines()[-8:])
    count = ssh(
        host,
        "sqlite3 ~/.codex/state_5.sqlite "
        + shlex.quote(f"select count(*) from threads where cwd = '{remote_path}';"),
        check=False,
    )
    checks["remote_thread_count"] = count.stdout.strip()
    if smoke_command:
        custom = ssh(host, f"cd {shlex.quote(remote_path)} && {smoke_command}", check=False)
        checks["custom_smoke_returncode"] = custom.returncode
        checks["custom_smoke_output"] = (custom.stdout + custom.stderr).strip()
        if custom.returncode != 0:
            raise MigrationError(f"Custom smoke command failed ({custom.returncode}):\n{checks['custom_smoke_output']}")
    if doctor.returncode != 0:
        raise MigrationError(f"codex doctor failed on {host}:\n{checks['codex_doctor_tail']}")
    return checks


def main() -> int:
    args = parse_args()
    project = ensure_project(args.project)
    codex_home = pathlib.Path(args.codex_home).expanduser().resolve()
    name = args.name or project.name
    timestamp = iso_now_compact()
    label = f"{name}-{timestamp}"
    remote_root = args.remote_root.rstrip("/")
    remote_path = f"{remote_root}/{name}"
    stage_path = f"{remote_root}/.migrations/{label}"

    report: dict[str, Any] = {
        "mode": "execute" if args.execute else "dry-run",
        "project": str(project),
        "host": args.host,
        "remote_path": remote_path,
        "stage_path": stage_path,
        "excluded_patterns": DEFAULT_EXCLUDES,
    }

    if args.skip_github_check:
        report["github"] = {"checked": False, "status": "skipped by --skip-github-check"}
    else:
        report["github"] = check_github_state(project, execute=args.execute, checkpoint_tracked=args.checkpoint_tracked)

    file_list = local_rsync_file_list(project)
    report["rsync_file_count"] = len(file_list)
    report["rsync_file_sample"] = file_list[:40]
    if args.list_files:
        report["rsync_files"] = file_list

    if not args.no_remote_check:
        check_remote_destination(args.host, remote_path, stage_path)
        home = remote_home(args.host)
        remote_codex_home = expand_remote_codex_home(args.remote_codex_home, home)
    else:
        remote_codex_home = args.remote_codex_home

    if args.no_codex:
        codex_payload = {"threads": [], "rollout_pairs": [], "session_index_updates": [], "goals": {"source_goals_db": None, "rows": []}}
    else:
        codex_payload = source_threads(codex_home, project, remote_path, remote_codex_home)
    report["codex"] = {
        "source_state_db": codex_payload.get("source_state_db"),
        "thread_count": len(codex_payload["threads"]),
        "goal_count": len(codex_payload["goals"]["rows"]),
        "source_goals_db": codex_payload["goals"]["source_goals_db"],
    }

    if not args.execute:
        print(json.dumps(report, indent=2))
        print("\nDry run only. Re-run with --execute after reviewing the report.")
        return 0

    execute_project_rsync(project, args.host, remote_path, stage_path)
    if codex_payload["threads"]:
        copy_rollouts(args.host, codex_payload["rollout_pairs"])
        report["codex_import"] = import_codex_payload(args.host, codex_payload, remote_codex_home, label)
    else:
        report["codex_import"] = {"threads_imported": 0, "goals": {"imported": 0}}
    report["smoke"] = smoke(args.host, remote_path, args.smoke_command)
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except MigrationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
