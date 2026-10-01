[[ -o interactive ]] || return
if [[ $TERM == xterm-ghostty ]]; then
  export COLORTERM=truecolor
  # Older hosts may not have Ghostty's terminal definition yet.
  if ! infocmp -x "$TERM" >/dev/null 2>&1; then
    export TERM=xterm-256color
  fi
fi
umask 077
export EDITOR=nvim VISUAL=nvim
export BAT_THEME="Rosé Pine"
export EZA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/eza"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/.ripgreprc"
typeset -U path
path=("$HOME/.local/bin" /opt/homebrew/bin /opt/homebrew/sbin /usr/local/bin /usr/local/sbin $path)
export NVM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvm"
[[ ! -s $NVM_DIR/nvm.sh ]] || source "$NVM_DIR/nvm.sh"
export HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS HIST_REDUCE_BLANKS HIST_IGNORE_SPACE NO_BEEP

autoload -Uz compinit
compinit
bindkey -e
bindkey '^K' up-line-or-history
bindkey '^J' down-line-or-history
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

[[ ! -r "$ZDOTDIR/aliases.zsh" ]] || source "$ZDOTDIR/aliases.zsh"

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

export DEJA_ACCEPT_KEY='^L' DEJA_CYCLE_KEY='^N'
export DEJA_TOGGLE_KEY='' DEJA_CYCLE_FUZZY_KEY='' DEJA_CYCLE_FUZZY_BACK_KEY=''
export DEJA_TOGGLE_EMPTY_KEY='' DEJA_WORD_ACCEPT_KEY=''
[[ ! -r "$HOME/.local/share/deja/init.zsh" ]] || source "$HOME/.local/share/deja/init.zsh"

prompt_theme="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/powerlevel10k/powerlevel10k.zsh-theme"
if [[ -r $prompt_theme ]]; then
  source "$prompt_theme"
  [[ ! -r "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"
else
  PROMPT='%F{#908caa}%n@%m%f %F{#c4a7e7}%~%f %# '
fi
[[ ! -r "$HOME/.zshrc.local" ]] || source "$HOME/.zshrc.local"

# Autosuggestions wrap shell widgets; syntax highlighting must load last.
for file in /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [[ ! -r $file ]] || { source "$file"; break; }
done
# Highlighting needs to see the widgets installed above.
for file in /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ ! -r $file ]] || { source "$file"; break; }
done
unset file nvm_init prompt_theme
