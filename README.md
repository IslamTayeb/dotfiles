# dotfiles

My shell/editor config managed with Nix. Works on macOS, Ubuntu, and Arch.

## What's in here

- zsh with oh-my-zsh and powerlevel10k
- tmux with my usual plugins
- nvim (LazyVim setup)
- LSPs, formatters, modern CLI tools (fzf, ripgrep, etc.)

Everything installs automatically. No manual setup needed.

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

./install.sh
```

Shell reloads automatically. Open nvim once to finish plugin setup.

## Usage

```bash
./update.sh              # update everything
./setup-cron.sh          # auto-sync every 30min
```

Add packages: edit `home.packages` in `home.nix`, run `./update.sh`

Rollback: `home-manager generations` then `home-manager switch --rollback`

## New machine

```bash
# Install Nix, enable flakes (see above)
git clone <repo> ~/.config/nix-config
cd ~/.config/nix-config
# Update flake.nix for this machine
./install.sh
```

## Config locations

- Git: `programs.git` in home.nix
- Zsh: `programs.zsh` in home.nix  
- Tmux: `programs.tmux.extraConfig` in home.nix
- Nvim: `~/.config/nvim` (LazyVim handles it)

## How it works

Nix installs packages and LSPs. TPM handles tmux plugins. LazyVim handles nvim plugins. Keeps things simple while ensuring everything's actually installed.
