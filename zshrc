
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
[ -d "$HOME/.docker/completions" ] && fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit

# ── iTerm2 ───────────────────────────────────────────────────────────────────
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# ── Overlay ──────────────────────────────────────────────────────────────────
[ -f "$HOME/.zshrc.rmt" ] && source "$HOME/.zshrc.rmt"
