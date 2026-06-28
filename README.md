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
- run `scripts/install.sh` to activate Home Manager

If Nix is already installed and you cannot use sudo, run:

```bash
curl -fsSL https://raw.githubusercontent.com/IslamTayeb/dotfiles/main/bootstrap-no-sudo.sh | bash
```

## Add a new host

If bootstrap says the machine is missing from `flake.nix`, add it under `homeConfigurations`:

```nix
"username@hostname" = mkHomeConfig "x86_64-linux" "username" [ ];
```

Use the detected system from the bootstrap output, such as `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, or `aarch64-linux`.

Then continue the bootstrap script, or run:

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

## Edit things

- Packages: `home.packages` in `home.nix`
- Hosts: `homeConfigurations` in `flake.nix`
- Shell: `configs/shell/`
- Neovim: `configs/nvim/`
- Tmux: `configs/tmux/`
- OpenCode: `configs/opencode/`
- Other app configs: `configs/<app>/`

Home Manager symlinks managed configs into your home directory.

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
