# =========================================================
# Environment
# =========================================================

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export EDITOR="nvim"
export VISUAL="nvim"

# Man pages through bat
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
fi

export GPG_TTY=$(tty)

# Let the terminal advertise its own capabilities (Ghostty sets this itself).
# Forcing xterm-256color caps colour at 256 and breaks truecolor apps.
# export TERM=xterm-256color

# =========================================================
# PATH
# =========================================================

export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"
export PATH="$PATH:/Users/siva/.local/bin"   # pipx
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
export PATH="/Users/siva/.antigravity-ide/antigravity-ide/bin:$PATH"

# NOTE: both llvm@22 and plain llvm were on your PATH; the last line wins.
# LDFLAGS/CPPFLAGS below point at llvm@22 — drop whichever you don't want.
export PATH="/opt/homebrew/opt/llvm@22/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/llvm@22/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm@22/include"
# export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# =========================================================
# History
# =========================================================

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# =========================================================
# Shell behaviour
# =========================================================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT  # sort file10 after file9, not after file1

# =========================================================
# Completion
# =========================================================

fpath+=~/.zfunc
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # case-insensitive

# =========================================================
# Navigation
# =========================================================

# --cmd cd replaces cd with zoxide. Must come after compinit for completions.
eval "$(zoxide init --cmd cd zsh)"

# =========================================================
# Fuzzy finder
# =========================================================

if [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
  source /opt/homebrew/opt/fzf/shell/completion.zsh
fi

export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --prompt="  "
  --pointer="  "
  --preview-window=right:65%:wrap:border-left
'

export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

# Ctrl+F: file picker excluding hidden files
_fzf_file_no_hidden() {
  local cmd result
  cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
  result=$(eval "${cmd:-find . -type f}" | fzf --preview "$_FZF_PREVIEW_CMD") \
    && LBUFFER+="$result"
  zle reset-prompt
}
zle -N _fzf_file_no_hidden

# =========================================================
# Aliases
# =========================================================

alias n='nvim'
alias vim='nvim'

alias ls='eza --icons'
alias ll='eza -lh --icons --git'
alias la='eza -lah --icons --git'
alias tree='eza --tree --icons'
compdef eza=ls

alias diff='diff --color=auto'
alias df='df -h'
alias -- -='cd -'

alias glog='PAGER="less -F -X" git log'
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'

# Replacing these changes flag behaviour — rg skips gitignored files, bat
# paginates. Uncomment only if you want that.
# alias grep='rg --color=auto'
# alias cat='bat'

# =========================================================
# Keybindings
# =========================================================

ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

ZVM_VI_HIGHLIGHT_BACKGROUND=none
ZVM_VI_HIGHLIGHT_FOREGROUND=none
ZVM_VI_HIGHLIGHT_EXTRASTYLE=none

# zsh-vi-mode resets all bindings on init, so custom bindings
# must be registered via this hook to survive.
zvm_after_init() {
  bindkey '^[[1;5C' forward-word              # Ctrl+Right
  bindkey '^[[1;5D' backward-word             # Ctrl+Left
  bindkey '^F' _fzf_file_no_hidden            # Ctrl+F, no hidden files
  bindkey '^\' autosuggest-toggle             # Ctrl+\
  bindkey '^[[A' history-substring-search-up  # Up
  bindkey '^[[B' history-substring-search-down
}

# =========================================================
# Plugins
# =========================================================

ZPLUGINDIR="$XDG_CONFIG_HOME/zsh/plugins"

_zplugin_load() {
  local plugin_path="${ZPLUGINDIR}/${2}"
  if [[ ! -d "$plugin_path" ]]; then
    mkdir -p "$ZPLUGINDIR"
    echo "Installing ${2}..."
    git clone --depth=1 "https://github.com/${1}/${2}" "$plugin_path" \
      || { echo "ERROR: failed to install ${2}" >&2; return 1; }
  fi
  source "${plugin_path}/${2}.plugin.zsh"
}

zplugin-update() {
  local dir
  for dir in "${ZPLUGINDIR}"/*/; do
    echo "Updating ${dir:t}..."
    git -C "$dir" pull --ff-only
  done
}

_zplugin_load zsh-users zsh-autosuggestions
_zplugin_load zsh-users zsh-history-substring-search
_zplugin_load jeffreytse zsh-vi-mode
_zplugin_load zdharma-continuum fast-syntax-highlighting

# =========================================================
# Prompt
# =========================================================

export VIRTUAL_ENV_DISABLE_PROMPT=1
eval "$(oh-my-posh init zsh --config ~/themes.json)"
