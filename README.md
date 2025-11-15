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

- gh, mise, neofetch, zed, rstudio, wireshark, linearmouse

Everything installs automatically and syncs across machines.

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
./scripts/setup-cron.sh          # auto-sync every 30min
```

Add packages: edit `home.packages` in `home.nix`, run `./scripts/update.sh`

Rollback: `home-manager generations` then `home-manager switch --rollback`

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

**On your main editing machine:**

```bash
cd ~/.config/nix-config
./scripts/setup-cron.sh  # Auto-commits changes every 30 min
```

**On secondary machines (to get updates):**

```bash
cd ~/.config/nix-config
git pull && ./scripts/update.sh
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
├── scripts/                   # Installation & update scripts
└── logs/                      # Auto-sync logs
```

## Config locations

All configs are in `configs/` and automatically symlinked to `~/.config/` by home-manager.

- **Nix packages**: Edit `home.packages` in `home.nix`
- **Application configs**: Edit files in `configs/<app>/`
- **Shell**: `configs/shell/zshrc`
- **Window management**: `configs/yabai/`, `configs/skhd/`

## How it works

Nix installs packages and LSPs. TPM handles tmux plugins. LazyVim handles nvim plugins. Keeps things simple while ensuring everything's actually installed.
