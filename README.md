# dotfiles

My shell/editor config managed with Nix. Works on macOS, Ubuntu, and Arch.

## What's in here

**Development Tools:**

- **Neovim** (LazyVim setup) - Full IDE experience
- **Zsh** with oh-my-zsh and powerlevel10k - Beautiful shell
- **Tmux** - Terminal multiplexer with plugins
- **LSPs & Formatters** - lua, nix, bash, typescript, python, rust, go
- **Modern CLI Tools** - fzf, ripgrep, zoxide, bat, eza, btop

**macOS Window Management:**

- **Yabai** - Tiling window manager
- **SKHD** - Hotkey daemon
- **Sketchybar** - Custom menu bar
- **Karabiner** - Keyboard customization

**Other Tools:**

- gh, mise, neofetch, opencode, zed, rstudio, wireshark, linearmouse

Everything installs automatically and can be updated manually across machines.

## Quick Setup (One Command)

```bash
curl -fsSL https://raw.githubusercontent.com/IslamTayeb/dotfiles/main/bootstrap.sh | bash
```

That's it! The script will:

- Install Nix (if needed)
- Enable flakes
- Clone your dotfiles
- Auto-detect your system (macOS/Linux, x86_64/aarch64)
- Guide you through configuration
- Install everything

## GitHub Authentication (Important!)

To avoid API rate limits and enable private GitHub access, set up authentication:

### Option 1: Using GitHub CLI (Recommended)

```bash
# If gh is already installed
gh auth login

# If not installed, Nix will install it for you
# Then after bootstrap completes:
gh auth login
```

### Option 2: Manual Token Setup (for servers without gh)

```bash
# Get a token at: https://github.com/settings/tokens (classic token with 'repo' scope)

# Add to Nix config (for avoiding rate limits)
echo "access-tokens = github.com=YOUR_TOKEN_HERE" >> ~/.config/nix/nix.conf

# For private HTTPS remotes
git config --global credential.helper store
echo "https://YOUR_TOKEN_HERE@github.com" >> ~/.git-credentials
chmod 600 ~/.git-credentials
```

## Manual Setup (if you prefer)

<details>
<summary>Click to expand manual instructions</summary>

```bash
# Install Nix
sh <(curl -L https://nixos.org/nix/install)

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

# Clone and setup
git clone https://github.com/IslamTayeb/dotfiles.git ~/.config/nix-config
cd ~/.config/nix-config

# Add your machine to flake.nix homeConfigurations
# Then:
chmod +x scripts/*.sh
./scripts/install.sh
```

</details>

Shell reloads automatically. Open nvim once to finish plugin setup.

## Usage

```bash
./scripts/update.sh              # update everything
```

Add packages: edit `home.packages` in `home.nix`, run `./scripts/update.sh`

Rollback: `home-manager generations` then `home-manager switch --rollback`

OpenCode note: `configs/opencode/` syncs automatically, and Home Manager installs the custom tool dependencies for you when `package.json` or `bun.lock` changes.

## New Machine Setup

### One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/IslamTayeb/dotfiles/main/bootstrap.sh | bash
```

### What it does

1. Installs Nix (if not present)
2. Enables flakes
3. Clones your dotfiles to `~/.config/nix-config`
4. Auto-detects system (macOS/Linux, architecture)
5. Prompts you to add your machine to `flake.nix` (if new)
6. Runs installation

### After Installation

**On secondary machines (to get updates):**

```bash
cd ~/.config/nix-config
git pull && ./scripts/update.sh
```

### Updating a Remote/Secondary Machine Without Breaking It

If your remote machine (e.g. `imt11@coltrane`) already has this repo set up and you want to pull the latest changes:

```bash
cd ~/.config/nix-config

# 1. Stash any local changes (if any)
git stash

# 2. Pull the latest from GitHub
git pull origin main

# 3. Reapply local changes (if you stashed anything)
git stash pop

# 4. Rebuild the Home Manager config
./scripts/update.sh
```

If Home Manager fails due to a conflicting file (e.g. an existing `~/.config/opencode` directory that isn't a symlink yet), move the old one out of the way first:

```bash
mv ~/.config/opencode ~/.config/opencode.backup
./scripts/update.sh
```

Things that happen automatically on `./scripts/update.sh`:
- Nix packages are installed/updated
- All config symlinks are created/updated
- OpenCode tool dependencies (`node_modules/`) are installed via `bun install`
- oh-my-zsh, zsh plugins, powerlevel10k, and TPM are installed if missing

Things that are safe across systems:
- Shell paths (`.local/bin`, `.opencode/bin`, `assay-finder/bin`, `.cargo/bin`, etc.) are only added to `PATH` if the directory exists
- Conda auto-detects from multiple known install locations instead of checking usernames
- `pyenv` and `mise` only initialize if the binary is present
- macOS-only tools are skipped on Linux automatically

**If something breaks on the remote machine:**

```bash
# Roll back to the previous Home Manager generation
home-manager generations
home-manager switch --rollback

# Or rebuild from the current config
./scripts/update.sh
```

### Ubuntu/Debian Servers

Same one-liner works! The bootstrap script auto-detects Linux and uses multi-user installation:

```bash
curl -fsSL https://raw.githubusercontent.com/IslamTayeb/dotfiles/main/bootstrap.sh | bash
```

macOS-specific tools (yabai, skhd, karabiner) are automatically skipped on Linux.

## Directory Structure

```
├── flake.nix, home.nix        # Main Nix configuration
├── configs/                   # All application configs
│   ├── shell/                 # zshrc, p10k.zsh
│   ├── tmux/                  # tmux.conf
│   ├── nvim/                  # Neovim (LazyVim)
│   ├── opencode/              # OpenCode config + custom tools
│   ├── btop/                  # System monitor
│   ├── gh/                    # GitHub CLI
│   ├── mise/                  # Runtime version manager
│   ├── zed/                   # Zed editor
│   ├── yabai/                 # Window manager (macOS)
│   ├── skhd/                  # Hotkey daemon (macOS)
│   ├── sketchybar/            # Menu bar (macOS)
│   ├── karabiner/             # Keyboard customizer (macOS)
│   ├── linearmouse/           # Mouse settings (macOS)
│   ├── rstudio/               # R Studio
│   └── wireshark/             # Network analyzer
└── scripts/                   # Installation & update scripts
```

## Config locations

All configs are in `configs/` and automatically symlinked to `~/.config/` by home-manager.

- **Nix packages**: Edit `home.packages` in `home.nix`
- **Application configs**: Edit files in `configs/<app>/`
- **Shell**: `configs/shell/zshrc`
- **Window management**: `configs/yabai/`, `configs/skhd/`
- **OpenCode**: `configs/opencode/`

If you pull this repo on another machine and run `./scripts/update.sh`, the OpenCode config and its custom tool runtime are set up automatically.

## How it works

Nix installs packages and LSPs. TPM handles tmux plugins. LazyVim handles nvim plugins. Keeps things simple while ensuring everything's actually installed.
