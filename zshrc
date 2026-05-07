
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
if [[ "$OSTYPE" == darwin* ]]; then
    alias vi='/opt/homebrew/bin/nvim'
    alias vim='/opt/homebrew/bin/nvim'
else
    alias vi='/usr/bin/nvim'
    alias vim='/usr/bin/nvim'
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
plugins=(git macos docker docker-compose tmux)
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# Run our own compinit only when OMZ isn't loaded (OMZ runs its own).
if [ ! -f "$ZSH/oh-my-zsh.sh" ]; then
    autoload -Uz compinit
    compinit
fi

# ── iTerm2 ───────────────────────────────────────────────────────────────────
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# ── Overlay ──────────────────────────────────────────────────────────────────
[ -f "$HOME/.zshrc.rmt" ] && source "$HOME/.zshrc.rmt"
