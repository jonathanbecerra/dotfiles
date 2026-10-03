[[ -o interactive ]] || return

# Terminal
if [[ $TERM == xterm-ghostty ]]; then
  export COLORTERM=truecolor
  if ! infocmp -x "$TERM" >/dev/null 2>&1; then
    export TERM=xterm-256color
  fi
fi

# Shell
umask 077

# Exports
export EDITOR=nvim VISUAL=nvim
export BAT_THEME="Rosé Pine"
export EZA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/eza"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/.ripgreprc"

# Paths
typeset -U path
path=(
  "$HOME/.local/bin"
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /usr/local/bin
  /usr/local/sbin
  $path
)

# Node
export NVM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvm"
[[ ! -s $NVM_DIR/nvm.sh ]] || source "$NVM_DIR/nvm.sh"

# History
export HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS HIST_REDUCE_BLANKS HIST_IGNORE_SPACE NO_BEEP

# Completion
autoload -Uz compinit
compinit

# Key bindings
bindkey -e
bindkey '^K' up-line-or-history
bindkey '^J' down-line-or-history
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# Aliases
[[ ! -r "$ZDOTDIR/aliases.zsh" ]] || source "$ZDOTDIR/aliases.zsh"

# FZF
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --color=fg:#e0def4,bg:#191724,hl:#ebbcba,fg+:#e0def4,bg+:#26233a,hl+:#eb6f92,info:#9ccfd8,prompt:#c4a7e7,pointer:#ebbcba,marker:#31748f,spinner:#f6c177,header:#9ccfd8,border:#403d52'
if (( $+commands[fzf] )); then
  if fzf --zsh >/dev/null 2>&1; then
    eval "$(fzf --zsh)"
  else
    for file in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/fzf/key-bindings.zsh; do
      [[ ! -r $file ]] || { source "$file"; break; }
    done
  fi
fi

# Prompt
prompt_theme="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/powerlevel10k/powerlevel10k.zsh-theme"
if [[ -r $prompt_theme ]]; then
  source "$prompt_theme"
  [[ ! -r "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"
else
  PROMPT='%F{#f6c177}%n@%m%f %F{#c4a7e7}%~%f %# '
fi

# Local overrides
[[ ! -r "$HOME/.zshrc.local" ]] || source "$HOME/.zshrc.local"

# Plugins
for file in /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [[ ! -r $file ]] || { source "$file"; break; }
done
for file in /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ ! -r $file ]] || { source "$file"; break; }
done
unset file prompt_theme
