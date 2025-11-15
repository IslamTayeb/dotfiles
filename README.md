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

## New machine setup

### 1. Install Nix

```bash
sh <(curl -L https://nixos.org/nix/install)
```

### 2. Enable flakes

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
```

### 3. Clone your dotfiles

```bash
git clone https://github.com/IslamTayeb/dotfiles.git ~/.config/nix-config
cd ~/.config/nix-config
```

### 4. Update for this machine

Edit `flake.nix` and add your machine's config:

```nix
homeConfigurations = {
  "islamtayeb@Islams-MacBook-Pro" = mkHomeConfig "aarch64-darwin" "islamtayeb" [ ];
  "your-username@new-machine" = mkHomeConfig "aarch64-darwin" "your-username" [ ];  # Add this
};
```

### 5. Run installation

```bash
chmod +x scripts/*.sh
./scripts/install.sh
```

### 6. (Optional) Setup auto-commit

If this is your main machine where you edit configs:

```bash
./scripts/setup-cron.sh
```

This auto-commits changes every 30 min so other machines can pull updates.

### 7. Pull updates from other machines

Whenever you want to sync configs from your main machine:

```bash
cd ~/.config/nix-config
git pull
./scripts/update.sh
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
