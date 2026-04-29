#!/usr/bin/env bash
# install.sh — Install dotfiles via symlinks (default) or copies (--copy).
#
# Usage: ./install.sh [--copy]
#   Default: creates symlinks (host, VDI)
#   --copy:  copies files (devcontainer — dotfiles may be on tmpfs/volume)
set -euo pipefail

MODE="symlink"
[ "${1:-}" = "--copy" ] && MODE="copy"

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# ── Helpers ──────────────────────────────────────────────────────────────────

backup_and_remove() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/"
        echo "  Backed up: $target -> $BACKUP_DIR/"
    fi
}

link_or_copy() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"

    backup_and_remove "$dest"

    if [ "$MODE" = "symlink" ]; then
        ln -sf "$src" "$dest"
        echo "  Linked: $dest -> $src"
    else
        if [ -d "$src" ]; then
            cp -a "$src" "$dest"
        else
            cp "$src" "$dest"
        fi
        echo "  Copied: $src -> $dest"
    fi
}

# ── Ensure target directories exist ─────────────────────────────────────────

mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.config/zsh"

# ── Install dotfiles ────────────────────────────────────────────────────────

echo "Installing dotfiles ($MODE mode)..."

# Shell
link_or_copy "$DOTFILES_DIR/zshrc"     "$HOME/.zshrc"
link_or_copy "$DOTFILES_DIR/zprofile"  "$HOME/.zprofile"

# Git
link_or_copy "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"
link_or_copy "$DOTFILES_DIR/config/git" "$HOME/.config/git"

# Terminal
link_or_copy "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"

# Editors
link_or_copy "$DOTFILES_DIR/ideavimrc" "$HOME/.ideavimrc"
link_or_copy "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"

# Colour scheme (cloned from upstream if not already present)
if [ ! -d "$HOME/.config/base16-shell" ]; then
    git clone https://github.com/chriskempson/base16-shell.git "$HOME/.config/base16-shell"
fi

# Scripts
link_or_copy "$DOTFILES_DIR/local/bin/tmux-save.sh"  "$HOME/.local/bin/tmux-save.sh"
link_or_copy "$DOTFILES_DIR/local/bin/status.sh"     "$HOME/.local/bin/status.sh"

# ── Machine-specific templates ───────────────────────────────────────────────
if [ ! -f /.dockerenv ] && [ ! -f "$HOME/.secrets" ]; then
    echo ""
    echo "NOTE: ~/.secrets does not exist."
    echo "  Copy the template and fill in your values:"
    echo "  cp $DOTFILES_DIR/secrets.example ~/.secrets"
fi

echo ""
echo "Done."
