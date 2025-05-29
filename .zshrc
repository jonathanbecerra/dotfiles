# Platform detection
IS_MACOS=false
IS_LINUX=false

case "$OSTYPE" in
  darwin*) IS_MACOS=true ;;
  linux*)  IS_LINUX=true ;;
esac

# Aliases
alias nfck="echo    󰊠 󰅨 󱃿"
alias src="source ~/.zshrc"
alias cl="clear"
alias lg="lazygit"
alias vi="nvim"
alias vim="nvim"
alias ktmux="tmux kill-server"
alias lsblko="lsblk -o NAME,LABEL,SIZE,FSTYPE,MOUNTPOINT"

# Evalualtions
eval "$(starship init zsh)"

if $IS_MACOS; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Exports
export TERMINAL=kitty
export PATH="$HOME/.local/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

if $IS_MACOS; then
  export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

  export ANDROID_HOME=$HOME/Library/Android/sdk
  export PATH=$PATH:$ANDROID_HOME/emulator
  export PATH=$PATH:$ANDROID_HOME/platform-tools
fi

# Plugins
source "${HOME}/.zsh-autosuggestions/zsh-autosuggestions.zsh"
source "${HOME}/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "${HOME}/.zsh-bat/zsh-bat.plugin.zsh"

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# Terminal configurations
if [[ "$TERM" == "xterm-ghostty" ]]; then
  export TERM=xterm-256color
fi

if $IS_LINUX; then
  if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    tmux attach-session -t default || tmux new-session -s default
  fi
fi


