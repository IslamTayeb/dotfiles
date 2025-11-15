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

## First time setup

```bash
# Install Nix
sh <(curl -L https://nixos.org/nix/install)

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

# Clone and setup
git clone <your-repo> ~/.config/nix-config
cd ~/.config/nix-config

# Edit flake.nix - change username
# Edit home.nix - change git config

./scripts/install.sh
```

Shell reloads automatically. Open nvim once to finish plugin setup.

## Usage

```bash
./scripts/update.sh              # update everything
./scripts/setup-cron.sh          # auto-sync every 30min
```

Add packages: edit `home.packages` in `home.nix`, run `./scripts/update.sh`

Rollback: `home-manager generations` then `home-manager switch --rollback`

## New machine

```bash
# Install Nix, enable flakes (see above)
git clone <repo> ~/.config/nix-config
cd ~/.config/nix-config
# Update flake.nix for this machine
./scripts/install.sh
```

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
