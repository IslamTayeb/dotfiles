# dotfiles

Nix/Home Manager dotfiles for my shell, editor, tmux, CLI tools, and app configs.

## Install on a new machine

```bash
curl -fsSL https://raw.githubusercontent.com/IslamTayeb/dotfiles/main/bootstrap.sh | bash
```

The bootstrap script will:

- install Nix if needed
- enable flakes
- clone this repo to `~/.config/nix-config`
- detect `username@hostname` and system architecture
- add the machine to `flake.nix` if missing
- run `scripts/install.sh` to activate Home Manager

If Nix is already installed and you cannot use sudo, run:

```bash
curl -fsSL https://raw.githubusercontent.com/IslamTayeb/dotfiles/main/bootstrap-no-sudo.sh | bash
```

## Add a new host

Bootstrap adds the detected machine to `flake.nix` automatically. If it cannot, add it under `homeConfigurations`:

```nix
"username@hostname" = mkHomeConfig "x86_64-linux" "username" [ ];
```

Use the detected system from the bootstrap output, such as `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, or `aarch64-linux`.

Then run:

```bash
cd ~/.config/nix-config
./scripts/install.sh
```

## After install

```bash
gh auth login        # optional, avoids GitHub rate limits/private repo issues
nvim                 # let LazyVim finish plugin setup
tmux                 # tmux/TPM plugins are installed by the setup
```

The installer may ask to make `zsh` the default shell.

## Update

```bash
cd ~/.config/nix-config
git pull
./scripts/update.sh
```

`scripts/update.sh` updates flake inputs, rebuilds Home Manager, and switches to the new generation.

## Ghostty

The terminal config lives at `configs/ghostty/config.ghostty` and Home Manager
links it to `~/.config/ghostty/config.ghostty`. That is the current filename,
verified against Ghostty 1.3.1; older releases used plain `config`. On macOS
Ghostty searches `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`
*first*, so keep that path empty or absent or it will shadow the dotfiles config.

The config sets no `font-family`: Ghostty's built-in JetBrains Mono plus its
bundled `Symbols Nerd Font` fallback already cover the powerlevel10k
`nerdfont-v3` icons, so a new machine needs no font installed. Check with:

```bash
ghostty +validate-config
ghostty +show-config --changes-only
ghostty +show-face --string=""
```

## Edit things

- Packages: `home.packages` in `home.nix`
- Hosts: `homeConfigurations` in `flake.nix`
- Shell: `configs/shell/`
- Neovim: `configs/nvim/`
- Tmux: `configs/tmux/`
- Ghostty: `configs/ghostty/config.ghostty`
- OpenCode: `configs/opencode/`
- Codex profiles and personal skills: `configs/codex/`
- Other app configs: `configs/<app>/`

Home Manager symlinks managed configs into your home directory.

## Codex sync

Dotfiles installs portable Codex state with:

```bash
./scripts/sync-codex.sh --profile auto --write-config
```

This syncs personal skills and a host-specific `~/.codex/config.toml`, backing up the previous config first. It does not sync Codex auth, sessions, logs, caches, state databases, or app-server sockets.

Profiles currently include `macos`, `resembool`, `typhon`, and generic `linux`.

## Recover

Rollback to the previous Home Manager generation:

```bash
home-manager generations
home-manager switch --rollback
```

If Home Manager fails because a config path already exists, move the old path aside and rerun the update:

```bash
mv ~/.config/opencode ~/.config/opencode.backup
./scripts/update.sh
```

Replace `opencode` with the conflicting config directory if needed.
