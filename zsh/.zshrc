HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
alias n='nvim'

# oh-my-posh themes
eval "$(oh-my-posh init zsh --config ~/themes.json)"
export TERM=xterm-256color

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

eval "$(zoxide init --cmd cd zsh)"


export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"

# Created by `pipx` on 2026-07-07 01:17:52
export PATH="$PATH:/Users/siva/.local/bin"
export PATH="/opt/homebrew/opt/llvm@22/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/llvm@22/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm@22/include"

fpath+=~/.zfunc; autoload -Uz compinit; compinit

zstyle ':completion:*' menu select
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"

# Added by Antigravity IDE
export PATH="/Users/siva/.antigravity-ide/antigravity-ide/bin:$PATH"
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
