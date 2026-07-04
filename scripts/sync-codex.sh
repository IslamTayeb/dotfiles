#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
PROFILE="auto"
WRITE_CONFIG=false
INSTALL_APP_CONFIG=true

usage() {
  cat <<'EOF'
Usage: scripts/sync-codex.sh [--profile auto|macos|resembool|vm-typhon] [--write-config] [--skills-only]

Installs portable Codex state from dotfiles:
- personal skills from configs/codex/skills
- optional host profile from configs/codex/profiles/<profile>.toml
- macOS Codex app remote-project config from configs/codex/codex-app/config.json

Never syncs auth.json, logs, sessions, caches, or state databases.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile)
      PROFILE="${2:?missing profile}"
      shift 2
      ;;
    --write-config)
      WRITE_CONFIG=true
      shift
      ;;
    --skills-only)
      WRITE_CONFIG=false
      INSTALL_APP_CONFIG=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

detect_profile() {
  local host os
  host="$(hostname -s 2>/dev/null || hostname)"
  os="$(uname -s)"
  case "$host" in
    resembool) echo "resembool"; return ;;
    typhon|vm-typhon) echo "vm-typhon"; return ;;
  esac
  case "$os" in
    Darwin) echo "macos" ;;
    *) echo "linux" ;;
  esac
}

if [ "$PROFILE" = "auto" ]; then
  PROFILE="$(detect_profile)"
fi

mkdir -p "$CODEX_HOME/skills"

if [ -d "$SCRIPT_DIR/configs/codex/skills" ]; then
  for skill_dir in "$SCRIPT_DIR"/configs/codex/skills/*; do
    [ -d "$skill_dir" ] || continue
    name="$(basename "$skill_dir")"
    if [ "$name" = ".system" ]; then
      continue
    fi
    rm -rf "$CODEX_HOME/skills/$name"
    mkdir -p "$CODEX_HOME/skills/$name"
    cp -R "$skill_dir"/. "$CODEX_HOME/skills/$name"/
  done
fi

if [ "$WRITE_CONFIG" = true ]; then
  profile_path="$SCRIPT_DIR/configs/codex/profiles/$PROFILE.toml"
  if [ ! -f "$profile_path" ]; then
    echo "No Codex profile found: $profile_path" >&2
    exit 1
  fi
  mkdir -p "$CODEX_HOME"
  if [ -f "$CODEX_HOME/config.toml" ]; then
    cp "$CODEX_HOME/config.toml" "$CODEX_HOME/config.toml.backup.$(date +%Y%m%d%H%M%S)"
  fi
  cp "$profile_path" "$CODEX_HOME/config.toml"
fi

if [ "$INSTALL_APP_CONFIG" = true ] && [ "$(uname -s)" = "Darwin" ] && [ -f "$SCRIPT_DIR/configs/codex/codex-app/config.json" ]; then
  mkdir -p "$CODEX_HOME/codex-app"
  if [ -f "$CODEX_HOME/codex-app/config.json" ]; then
    cp "$CODEX_HOME/codex-app/config.json" "$CODEX_HOME/codex-app/config.json.backup.$(date +%Y%m%d%H%M%S)"
  fi
  cp "$SCRIPT_DIR/configs/codex/codex-app/config.json" "$CODEX_HOME/codex-app/config.json"

  global_state="$CODEX_HOME/.codex-global-state.json"
  if [ -f "$global_state" ] && command -v node >/dev/null 2>&1; then
    cp "$global_state" "$global_state.backup.$(date +%Y%m%d%H%M%S)"
    CODEX_APP_CONFIG="$SCRIPT_DIR/configs/codex/codex-app/config.json" \
    CODEX_GLOBAL_STATE="$global_state" \
    node <<'NODE'
const crypto = require("crypto");
const fs = require("fs");

const configPath = process.env.CODEX_APP_CONFIG;
const statePath = process.env.CODEX_GLOBAL_STATE;
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const state = JSON.parse(fs.readFileSync(statePath, "utf8"));

const desired = [];
for (const connection of config.remoteConnections ?? []) {
  const hostId = `remote-ssh-discovered:${connection.sshAlias}`;
  for (const project of connection.projects ?? []) {
    desired.push({
      hostId,
      remotePath: project.remotePath,
      label: project.label,
    });
  }
}

const managedHostIds = new Set(desired.map((project) => project.hostId));
const existing = Array.isArray(state["remote-projects"])
  ? state["remote-projects"]
  : [];
const existingByKey = new Map(
  existing.map((project) => [
    `${project.hostId}\0${project.remotePath}`,
    project,
  ]),
);

const reconciled = desired.map((project) => {
  const previous = existingByKey.get(`${project.hostId}\0${project.remotePath}`);
  return {
    id: previous?.id ?? crypto.randomUUID(),
    hostId: project.hostId,
    remotePath: project.remotePath,
    label: project.label,
  };
});

const removedIds = new Set(existing.map((project) => project.id));
for (const project of reconciled) {
  removedIds.delete(project.id);
}
state["remote-projects"] = reconciled;

const managedIds = new Set(reconciled.map((project) => project.id));
const existingOrder = Array.isArray(state["project-order"])
  ? state["project-order"]
  : [];
state["project-order"] = [
  ...reconciled.map((project) => project.id),
  ...existingOrder.filter(
    (id) => !managedIds.has(id) && !removedIds.has(id),
  ),
];

if (state["remote-connection-auto-connect-by-host-id"]) {
  for (const [hostId, enabled] of Object.entries(state["remote-connection-auto-connect-by-host-id"])) {
    if (enabled === true && !managedHostIds.has(hostId)) {
      delete state["remote-connection-auto-connect-by-host-id"][hostId];
    }
  }
  for (const hostId of managedHostIds) {
    state["remote-connection-auto-connect-by-host-id"][hostId] = true;
  }
}

if (Array.isArray(state["codex-managed-remote-connections"])) {
  state["codex-managed-remote-connections"] = state["codex-managed-remote-connections"].filter(
    (connection) => {
      if (managedHostIds.has(connection.hostId)) {
        return true;
      }
      const autoConnect = state["remote-connection-auto-connect-by-host-id"]?.[connection.hostId];
      return autoConnect !== true;
    },
  );
}

if (state["remote-connection-analytics-id-by-host-id"]) {
  const knownConnectionHostIds = new Set(
    (state["codex-managed-remote-connections"] ?? [])
      .map((connection) => connection.hostId)
      .filter(Boolean),
  );
  for (const hostId of Object.keys(state["remote-connection-analytics-id-by-host-id"])) {
    if (!managedHostIds.has(hostId) && !knownConnectionHostIds.has(hostId)) {
      delete state["remote-connection-analytics-id-by-host-id"][hostId];
    }
  }
}

if (Array.isArray(state["host-id-remote-control-allowed"])) {
  const allowed = new Set(
    state["host-id-remote-control-allowed"].filter(
      (hostId) => managedHostIds.has(hostId),
    ),
  );
  for (const hostId of managedHostIds) {
    allowed.add(hostId);
  }
  state["host-id-remote-control-allowed"] = [...allowed];
}

fs.writeFileSync(statePath, `${JSON.stringify(state)}\n`);
NODE
  fi
fi

echo "Synced Codex skills to $CODEX_HOME/skills"
if [ "$WRITE_CONFIG" = true ]; then
  echo "Wrote Codex profile: $PROFILE"
else
  echo "Skipped Codex config profile; pass --write-config to replace config.toml"
fi
