# ~/.zshrc — managed via /etc/skel by the hypratomic image.
# Override anything locally in ~/.zshrc.local (sourced at the bottom).

# --- History ---
HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE HIST_SAVE_NO_DUPS HIST_VERIFY INC_APPEND_HISTORY

# --- Completion ---
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# --- Keybindings ---
bindkey -e
bindkey '^R' history-incremental-search-backward

# --- Aliases ---
alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --git --group-directories-first'
alias la='eza -a --icons'
alias lt='eza --tree --level=2 --icons'
alias cat='bat --paging=never'
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'

# rpm-ostree shortcuts
alias os-status='rpm-ostree status'
alias os-upgrade='rpm-ostree upgrade'
alias os-rebase='rpm-ostree rebase'
alias os-rollback='rpm-ostree rollback'

# Git shortcuts
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'

# Flatpak + distrobox
alias fp='flatpak'
alias fpl='flatpak list --app'
alias dbx='distrobox'

# --- Tool integrations (only if tool is installed) ---
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v zoxide  >/dev/null && eval "$(zoxide init zsh)"
command -v fzf     >/dev/null && {
    source <(fzf --zsh) 2>/dev/null || true
}

# --- Paths ---
typeset -U path
path=($HOME/.local/bin $HOME/bin $path)

# --- Local overrides (not tracked by image) ---
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
