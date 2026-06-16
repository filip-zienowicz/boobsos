export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="ys"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# ── ls / ll ──────────────────────────────────────────────────────────────────
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lgh --icons --group-directories-first'
    alias la='eza -lagh --icons --group-directories-first'
    alias l='eza -1 --icons'
else
    alias ls='ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
fi

# ── cat → bat ────────────────────────────────────────────────────────────────
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --style=plain'
elif command -v batcat >/dev/null 2>&1; then
    alias cat='batcat --style=plain'
fi

alias grep='grep --color=auto'

# ── Historia ─────────────────────────────────────────────────────────────────
export HISTFILE=$HOME/.zsh_history
export HISTSIZE=50000
export SAVEHIST=50000
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_DUPS
