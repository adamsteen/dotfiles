
# ── History ──────────────────────────────────────────────────────────────────
# Inside the devcontainer we don't persist shell history. This reduces the
# set of on-disk files a prompt-injected session can read. Up-arrow still
# works within one shell — only the on-disk file goes away.
if [ -f /.dockerenv ]; then
    unset HISTFILE
    HISTSIZE=0
    SAVEHIST=0
else
    HISTFILE=~/.config/zsh/histfile
    HISTSIZE=20000
    SAVEHIST=20000
fi

# ── Vi mode ──────────────────────────────────────────────────────────────────
bindkey -v

# ── Aliases ──────────────────────────────────────────────────────────────────
alias tmux='tmux -2'
# nvim path comes from $HOMEBREW_PREFIX (set by `brew shellenv` in zprofile),
# so this works on both Apple Silicon (/opt/homebrew) and Linuxbrew
# (/home/linuxbrew/.linuxbrew). Falls back to PATH lookup in environments
# without brew (e.g. devcontainers).
if [ -n "${HOMEBREW_PREFIX:-}" ] && [ -x "$HOMEBREW_PREFIX/bin/nvim" ]; then
    alias vi="$HOMEBREW_PREFIX/bin/nvim"
    alias vim="$HOMEBREW_PREFIX/bin/nvim"
else
    alias vi='nvim'
    alias vim='nvim'
fi

# GlobalProtect (Palo Alto Networks VPN) — macOS only.
# launchctl + /Library/LaunchAgents/ are Darwin-specific; the launch
# agents won't exist on Linux / VDI / devcontainer sessions.
if [[ "$OSTYPE" == darwin* ]]; then
    alias start-globalprotect='launchctl load /Library/LaunchAgents/com.paloaltonetworks.gp.pangp*'
    alias stop-globalprotect='launchctl unload /Library/LaunchAgents/com.paloaltonetworks.gp.pangp*'
fi

# ── Completions ──────────────────────────────────────────────────────────────
# fpath additions must run before any compinit (ours below or OMZ's), or the
# extra completion functions won't be picked up.
[ -d "$HOME/.docker/completions" ] && fpath=("$HOME/.docker/completions" $fpath)

# ── Oh My Zsh ────────────────────────────────────────────────────────────────
# Loaded only if OMZ has been cloned into ~/.oh-my-zsh. install.sh skips that
# clone in the devcontainer by default; set INSTALL_OMZ=1 to opt in there.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
# `macos` plugin (tab/pfd/quick-look) only works on Darwin; omit elsewhere.
if [[ "$OSTYPE" == darwin* ]]; then
    plugins=(git macos docker docker-compose tmux vi-mode)
else
    plugins=(git docker docker-compose tmux vi-mode)
fi
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# Run our own compinit only when OMZ isn't loaded (OMZ runs its own).
if [ ! -f "$ZSH/oh-my-zsh.sh" ]; then
    autoload -Uz compinit
    compinit
fi

# ── iTerm2 ───────────────────────────────────────────────────────────────────
# iTerm2 is macOS-only — guard explicitly so the intent is obvious to readers
# (the test -e would already silently skip on Linux).
if [[ "$OSTYPE" == darwin* ]]; then
    test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
fi

# ── Overlay ──────────────────────────────────────────────────────────────────
[ -f "$HOME/.zshrc.rmt" ] && source "$HOME/.zshrc.rmt"
