alias cl='clear'
alias ll='ls -la'
alias la='ls -A'
alias '~~'='cd ~/'
alias '..'='cd ..'
if (( $+commands[eza] )); then
  eza() {
    local eza_bin=${commands[eza]}
    # Let the Rosé Pine theme file control icon and file colors.
    env -u EZA_COLORS -u EXA_COLORS -u LS_COLORS "$eza_bin" "$@"
  }
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza -la --icons=auto --group-directories-first'
  alias la='eza -a --icons=auto --group-directories-first'
fi
alias cat="bat"
alias ff='fastfetch'
alias vi='nvim'
alias vim='nvim'
alias lg='lazygit'
alias ld='lazydocker'
if (( $+commands[lazydocker] )); then
  lazydocker() {
    local lazydocker_bin=${commands[lazydocker]}
    # Use the same XDG config path on macOS and Linux.
    env "CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/lazydocker" "$lazydocker_bin" "$@"
  }
fi
if (( $+commands[docker-compose] )); then
  alias dc='docker-compose'
else
  alias dc='docker compose'
fi
glow() {
  # Pass an absolute style path for Glow versions that do not expand config paths.
  command glow --style "$HOME/.config/glow/styles/rose-pine.json" "$@"
}
mat() { glow "$@"; }
alias tms='bash "$HOME/.config/tmux/choose-session.sh"'
alias fzfc='fzf | xclip -selection clipboard'
(( $+commands[bat] )) || { (( $+commands[batcat] )) && alias bat='batcat'; }
(( $+commands[bat] || $+commands[batcat] )) && alias cat='bat'
(( $+commands[fd] )) || { (( $+commands[fdfind] )) && alias fd='fdfind'; }
