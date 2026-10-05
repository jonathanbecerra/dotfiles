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
alias ff='fastfetch'
alias zshr='exec env -u ZDOTDIR zsh -l'
alias vi='nvim'
alias vim='nvim'
alias lg='lazygit'
alias ld='lazydocker'
define() {
  if (( $# )); then
    whence -f -- "$@"
  else
    alias
  fi
}
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
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dcup='dc up -d'
alias dcdown='dc down'
alias dcrs='dc restart'
alias dcps='dc ps'
dlogs() {
  local container=${1:-}
  [[ -n $container ]] || { print -u2 'Usage: dlogs <container> [tail]'; return 2; }
  docker logs --tail "${2:-100}" --follow "$container"
}
dpt() {
  if (( $# )); then
    docker port "$1"
  else
    docker ps --format $'table {{.Names}}\t{{.Ports}}'
  fi
}
dst() {
  docker stats --no-stream --format $'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}'
}
dstall() {
  local running
  local -a containers
  running=$(docker ps -q) || return
  containers=(${(@f)running})
  if (( ! ${#containers[@]} )); then
    print 'No running containers.'
    return 0
  fi
  docker stop "${containers[@]}"
}
dts() {
  local container image reply volume mounts users
  local -a volumes
  (( $# == 1 )) || { print -u2 'Usage: dts <container>'; return 2; }
  container=$(docker container inspect --format '{{.Id}}' -- "$1") || return
  image=$(docker container inspect --format '{{.Image}}' "$container") || return
  mounts=$(docker container inspect --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{"\n"}}{{end}}{{end}}' "$container") || return
  volumes=(${(u)${(@f)mounts}})
  print "Container: $1 ($container)"
  print "Image: $image"
  if (( ${#volumes[@]} )); then
    print 'Volumes:'
    printf '  %s\n' "${volumes[@]}"
  else
    print 'Volumes: none'
  fi
  print 'Networks are preserved.'
  if ! read -q "reply?Remove this container, its image, and unused attached volumes? [y/N] "; then
    print
    print 'Cancelled.'
    return 1
  fi
  print
  docker rm -f "$container" || return
  for volume in "${volumes[@]}"; do
    users=$(docker ps -aq --filter "volume=$volume") || return
    if [[ -n $users ]]; then
      print "Keeping shared volume: $volume"
    else
      docker volume rm "$volume" || return
    fi
  done
  users=$(docker ps -aq --filter "ancestor=$image") || return
  if [[ -z $users ]]; then
    docker image rm "$image"
  else
    print "Keeping image used by another container: $image"
  fi
}
dtd() {
  local reply context
  context=$(docker context show) || return
  print "Docker context: $context"
  print 'This stops ALL containers and deletes unused containers, images, named/anonymous volumes, networks, and build cache.'
  print 'Every Docker project in this context is affected. Bind-mounted host files are kept.'
  if ! read -q "reply?Continue with the global Docker teardown? [y/N] "; then
    print
    print 'Cancelled.'
    return 1
  fi
  print
  dstall || return
  docker system prune --all --force || return
  docker volume prune --all --force
}

# Markdown
glow() {
  command glow --style "$HOME/.config/glow/styles/rose-pine.json" "$@"
}
mat() { glow "$@"; }

# Tmux and clipboard
alias tms='bash "$HOME/.config/tmux/choose-session.sh"'
fzfc() {
  local clipboard selected encoded file finder
  if (( $# == 1 )) && [[ -f $1 ]]; then
    selected=$(fzf <"$1") || return
  elif [[ -t 0 ]]; then
    if (( $+commands[fd] )); then
      finder=fd
    elif (( $+commands[fdfind] )); then
      finder=fdfind
    else
      print -u2 'fzfc: fd or fdfind is required when selecting a file'
      return 1
    fi
    file=$("$finder" --type f --hidden --exclude .git . | fzf) || return
    selected=$(<"$file")
  else
    selected=$(fzf "$@") || return
  fi
  if [[ $OSTYPE == darwin* ]]; then
    clipboard=(pbcopy)
  elif (( $+commands[wl-copy] )); then
    clipboard=(wl-copy)
  elif (( $+commands[xclip] )); then
    clipboard=(xclip -selection clipboard)
  elif (( $+commands[xsel] )); then
    clipboard=(xsel --clipboard --input)
  elif [[ -n ${SSH_TTY:-} && $+commands[base64] ]]; then
    encoded=$(print -rn -- "$selected" | base64 | tr -d '\n')
    if [[ -n ${TMUX:-} ]]; then
      printf '\033Ptmux;\033\033]52;c;%s\a\033\\' "$encoded"
    else
      printf '\033]52;c;%s\a' "$encoded"
    fi
    return
  else
    print -u2 'fzfc: no clipboard command found and no SSH terminal clipboard is available'
    return 1
  fi
  print -rn -- "$selected" | "${clipboard[@]}"
}

# Platform compatibility
(( $+commands[bat] )) || { (( $+commands[batcat] )) && alias bat='batcat'; }
(( $+commands[bat] || $+commands[batcat] )) && alias cat='bat'
(( $+commands[fd] )) || { (( $+commands[fdfind] )) && alias fd='fdfind'; }
