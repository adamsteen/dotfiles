
# ── Environment variables ────────────────────────────────────────────────────
if [[ "$OSTYPE" == darwin* ]]; then
    export VISUAL='/opt/homebrew/bin/nvim'
else
    export VISUAL='/usr/bin/nvim'
fi
export EDITOR=$VISUAL
export HOMEBREW_NO_ENV_HINTS=1
export NODE_OPTIONS="--max-old-space-size=8192"
export TERMINFO_DIRS=$TERMINFO_DIRS:$HOME/.local/share/terminfo

# Corporate CA (env-driven; set by work overlays or machine provisioning)
[ -s "${CORP_CA_PATH:-}" ] && export NODE_EXTRA_CA_CERTS="$CORP_CA_PATH"

if [[ "$OSTYPE" == darwin* ]]; then
    export DOCKER_DEFAULT_PLATFORM=linux/arm64
    export CHROME_EXECUTABLE=/Applications/Chromium.app/Contents/MacOS/Chromium
    export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)"
fi

# RMT Linux sessions: $USER is `adams@rmtp` on the VDI / jump host. Route
# docker through the user-accessible socket proxy started by
# `docker-proxy-start` so we can run docker / devcontainer without sudo.
# Personal Linux boxes keep their default docker behaviour.
if [[ "$OSTYPE" == linux* && "${USER:l}" == *@rmtp* ]]; then
    export DOCKER_HOST=unix:///tmp/docker-user.sock
fi

if [[ "$OSTYPE" == darwin* ]]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
    export DOTNET_ROOT="/opt/homebrew/opt/dotnet@8/libexec"
fi

# ── Secrets (never committed) ────────────────────────────────────────────────
[ -f "$HOME/.secrets" ] && source "$HOME/.secrets"

# ── PATH ─────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

if [[ "$OSTYPE" == darwin* ]]; then
    export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
    export PATH="$DOTNET_ROOT:$PATH"
    export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
    export PATH="$PATH:$ANDROID_HOME/platform-tools"
    export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
fi

# ── Shell init ───────────────────────────────────────────────────────────────
if [[ "$OSTYPE" == darwin* ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
eval "$(fnm env --use-on-cd 2>/dev/null)"
eval "$(rbenv init - --no-rehash zsh 2>/dev/null)"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# ── Container-only PATH hardening ────────────────────────────────────────────
# In a network-restricted devcontainer, move all $HOME paths (and /opt/java,
# which is user-writable inside the container's home-adjacent layer) to the
# END of PATH so /usr/bin takes precedence. Defends against a compromised
# plugin or tool that drops a binary into a user-writable location and tries
# to shadow `ls`, `git`, `cat`, etc.
if [ -f /.dockerenv ]; then
    _sys_path=""
    _usr_path=""
    for dir in ${(s.:.)PATH}; do
        case "$dir" in
            "$HOME"/*|/opt/java/*) _usr_path="${_usr_path:+$_usr_path:}$dir" ;;
            *)                     _sys_path="${_sys_path:+$_sys_path:}$dir" ;;
        esac
    done
    export PATH="${_sys_path}${_usr_path:+:$_usr_path}"
    unset _sys_path _usr_path dir
fi

export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

# ── Overlay (loaded last so it can see env/PATH from above) ──────────────────
[ -f "$HOME/.zprofile.rmt" ] && source "$HOME/.zprofile.rmt"
