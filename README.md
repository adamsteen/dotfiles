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

## Linux: sudo-less docker

`local/bin/docker-proxy-start` runs `socat` (with `sudo`) to expose the
root-owned `/var/run/docker.sock` as a world-writable user socket at
`/tmp/docker-user.sock`. Run it once after login to use `docker` and
`devcontainer` without `sudo`:

```sh
brew install socat    # one-shot per machine (or: sudo apt install socat)
docker-proxy-start    # one-shot per boot
docker ps             # no sudo
```

The proxy is launched via `setsid -f` so it survives the launching shell
closing — once started, it runs until reboot or until you stop it
explicitly:

```sh
docker-proxy-stop     # stops socat and removes /tmp/docker-user.sock
```

`zprofile` exports `DOCKER_HOST=unix:///tmp/docker-user.sock` only when both
`$OSTYPE` is `linux*` and `$USER` contains `@rmtp` (case-insensitive) — i.e.
the RMT VDI / jump-host environment. Personal Linux boxes keep their default
docker behaviour.

## Notes

Shell configs use `$OSTYPE` checks for macOS vs Linux differences. The nvim config uses `vim.fn.stdpath()` for portable paths. tmux uses OSC 52 for clipboard.
