#!/usr/bin/env bash
set -euo pipefail

shopt -s nullglob dotglob
project_root=${PROJECTS_DIR:-$HOME/Developer}
client_name=${1:-}
active_session=
existing_sessions=

if [[ -n ${TMUX:-} ]]; then
  if [[ -z $client_name ]]; then
    client_name=$(tmux display-message -p '#{client_name}')
  fi
  active_session=$(tmux display-message -p -c "$client_name" '#{session_name}')
  existing_sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | LC_ALL=C sort || true)
fi

list_choices() {
  local session_name directory
  while IFS= read -r session_name; do
    [[ -z $session_name || $session_name == "$active_session" ]] || printf '[session] %s\n' "$session_name"
  done <<<"$existing_sessions"
  for directory in "$project_root"/*/; do
    [[ -d $directory ]] && printf '%s\n' "${directory%/}"
  done
}

if [[ ${DRY_RUN:-0} == 1 ]]; then
  printf 'Would offer these sessions and project directories to fzf:\n'
  list_choices
  printf 'Would create a tmux session for a selected project and attach or switch clients.\n'
  exit 0
fi

selected=$(list_choices | fzf --no-sort --layout=reverse --prompt='Session> ' --delimiter='^\[session\] ' --nth=-1) || exit 0
[[ -n $selected ]] || exit 0

if [[ $selected == '[session] '* ]]; then
  session_name=${selected#'[session] '}
else
  project_path=$selected
  project_name=${project_path##*/}
  session_name=${project_name//[.:]/_}
  if ! tmux has-session -t "=$session_name" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$project_path"
  fi
fi

if [[ -n ${TMUX:-} ]]; then
  tmux switch-client -c "$client_name" -t "=$session_name"
else
  tmux attach-session -t "=$session_name"
fi
