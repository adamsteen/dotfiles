# dotfiles

Personal shell, git, terminal, and editor configuration.

Cross-platform: macOS host, Linux VDI, and Linux devcontainer.

## Install

```sh
git clone https://github.com/adamsteen/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` creates symlinks by default. Use `--copy` to copy instead (useful inside a devcontainer where the repo may live on a tmpfs or volume).

## Layout

- `zshrc`, `zprofile` — shell config
- `gitconfig`, `config/git/` — git config
- `tmux.conf` — tmux config
- `ideavimrc` — IdeaVim config
- `config/nvim/` — Neovim config
- `local/bin/` — small helper scripts
- `secrets.example` — template for `~/.secrets` (personal env vars, not committed)
- Oh My Zsh — cloned to `~/.oh-my-zsh` by `install.sh` and sourced from `zshrc` (skipped in devcontainer; set `INSTALL_OMZ=1` to opt in there)

## Machine-local overrides

- `~/.secrets` — sourced by `.zprofile` if present. Use for personal env vars / tokens.
- `~/.zshrc.rmt`, `~/.zprofile.rmt`, `~/.gitconfig.rmt` — sourced if present. Use for a work-specific overlay installed alongside these dotfiles.

## Notes

Shell configs use `$OSTYPE` checks for macOS vs Linux differences. The nvim config uses `vim.fn.stdpath()` for portable paths. tmux uses OSC 52 for clipboard.
