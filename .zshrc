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
alias ls='eza --icons'
alias ll='eza -lah --icons'
alias lt='eza --tree --icons'
alias ktmux="tmux kill-server"
alias lsblko="lsblk -o NAME,LABEL,SIZE,FSTYPE,MOUNTPOINT"

# Evalualtions
eval "$(starship init zsh)"

if $IS_MACOS; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

unset LS_COLORS

# Exports
export TERMINAL=kitty
export PATH="$HOME/.local/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
export VIVID_THEME="$HOME/.config/vivid/themes/junction.yml"
export EZA_COLORS="$(vivid generate "$VIVID_THEME")"

if $IS_MACOS; then
  export PATH="/usr/bin:$PATH"
  export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

  export ANDROID_HOME=$HOME/Library/Android/sdk
  export PATH=$PATH:$ANDROID_HOME/emulator
  export PATH=$PATH:$ANDROID_HOME/platform-tools
fi

# Plugins
source "${HOME}/.zsh-autosuggestions/zsh-autosuggestions.zsh"
source "${HOME}/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "${HOME}/.zsh-bat/zsh-bat.plugin.zsh"

typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#15ac91'            # mediumseagreen
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#efb080'            # lightsalmon
ZSH_HIGHLIGHT_STYLES[alias]='fg=#82d2ce'              # lightseagreen
ZSH_HIGHLIGHT_STYLES[option]='fg=#f8c762'             # gold
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#de3c72'           # hotpink
ZSH_HIGHLIGHT_STYLES[path]='fg=#af9cff'               # orchid
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f14c4c,bold' # crimson

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#af9cff' # orchid

# Terminal configurations
if [[ "$TERM" == "xterm-ghostty" ]]; then
  export TERM=xterm-256color
fi

if $IS_LINUX; then
  if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    tmux attach-session -t default || tmux new-session -s default
  fi
fi


