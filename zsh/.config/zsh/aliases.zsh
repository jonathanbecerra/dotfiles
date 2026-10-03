# Navigation
alias cl='clear'
alias '~~'='cd ~/'
alias '..'='cd ..'

# Listing
alias ll='ls -la'
alias la='ls -A'
if (( $+commands[eza] )); then
  eza() {
    local eza_bin=${commands[eza]}
    env -u EZA_COLORS -u EXA_COLORS -u LS_COLORS "$eza_bin" "$@"
  }
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza -la --icons=auto --group-directories-first'
  alias la='eza -a --icons=auto --group-directories-first'
fi

# Editors and tools
alias cat="bat"
alias ff='fastfetch'
alias zshr='exec env -u ZDOTDIR zsh -l'
alias vi='nvim'
alias vim='nvim'
alias lg='lazygit'
alias ld='lazydocker'
if (( $+commands[lazydocker] )); then
  lazydocker() {
    local lazydocker_bin=${commands[lazydocker]}
    env "CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/lazydocker" "$lazydocker_bin" "$@"
  }
fi

# Docker
if (( $+commands[docker-compose] )); then
  alias dc='docker-compose'
else
  alias dc='docker compose'
fi

# Markdown
glow() {
  command glow --style "$HOME/.config/glow/styles/rose-pine.json" "$@"
}
mat() { glow "$@"; }

# Tmux and clipboard
alias tms='bash "$HOME/.config/tmux/choose-session.sh"'
fzfc() {
  local clipboard
  if [[ $OSTYPE == darwin* ]]; then
    clipboard=(pbcopy)
  elif (( $+commands[wl-copy] )); then
    clipboard=(wl-copy)
  elif (( $+commands[xclip] )); then
    clipboard=(xclip -selection clipboard)
  elif (( $+commands[xsel] )); then
    clipboard=(xsel --clipboard --input)
  else
    print -u2 'fzfc: no clipboard command found (pbcopy, wl-copy, xclip, or xsel)'
    return 1
  fi
  fzf | "${clipboard[@]}"
}

# Platform compatibility
(( $+commands[bat] )) || { (( $+commands[batcat] )) && alias bat='batcat'; }
(( $+commands[bat] || $+commands[batcat] )) && alias cat='bat'
(( $+commands[fd] )) || { (( $+commands[fdfind] )) && alias fd='fdfind'; }
