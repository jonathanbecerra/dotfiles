#!/usr/bin/env bash
set -Eeuo pipefail
DOTFILES_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
target_dir=${DOTFILES_TARGET:-$HOME}
backup_dir=
umask 077

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}
case ${DRY_RUN:-0} in 0 | 1) ;; *) die 'DRY_RUN must be 0 or 1.' ;; esac
[[ $target_dir == /* && -d $target_dir && $target_dir != / ]] || die 'Target must be an existing home directory.'
target_dir=$(cd -- "$target_dir" && pwd -P)
backup_root="$target_dir/.local/state/dotfiles/backups"

run() {
  if [[ ${DRY_RUN:-0} == 1 ]]; then
    printf '  $'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

apt_locks_available() {
  local lock
  for lock in /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock; do
    [[ -e $lock ]] || continue
    if command -v fuser >/dev/null; then
      sudo fuser "$lock" >/dev/null 2>&1 && return 1
    elif ! sudo flock -n "$lock" -c true 2>/dev/null; then
      return 1
    fi
  done
}

apt_lock_holders() {
  local lock holders
  command -v fuser >/dev/null || return 0
  for lock in /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock; do
    [[ -e $lock ]] || continue
    holders=$(sudo fuser "$lock" 2>/dev/null || true)
    [[ -z $holders ]] || printf '  %s held by:%s\n' "$lock" "$holders"
  done
}

wait_for_apt() {
  local attempt
  [[ ${DRY_RUN:-0} == 1 ]] && return 0
  command -v sudo >/dev/null || die 'Install sudo before installing Linux dotfiles.'
  for ((attempt = 1; attempt <= 60; attempt++)); do
    apt_locks_available && return 0
    ((attempt == 1)) && printf 'Waiting for another apt process to finish...\n'
    if ((attempt > 1 && attempt % 10 == 0)); then
      printf 'Still waiting (%ss).\n' "$((attempt * 2))"
      apt_lock_holders
    fi
    sleep 2
  done
  die 'APT is still busy after 120 seconds. Check the process holding the apt or dpkg lock, then retry.'
}

time_sync_service() {
  local service
  for service in systemd-timesyncd chrony chronyd ntpsec ntp openntpd; do
    [[ $(systemctl show -p LoadState --value "$service.service" 2>/dev/null) == loaded ]] || continue
    printf '%s\n' "$service"
    return 0
  done
  return 1
}

ensure_time_sync() {
  local synchronized attempt service
  [[ ${TIME_SYNC_READY:-0} == 1 ]] && return 0
  if [[ ${DRY_RUN:-0} != 1 ]]; then
    command -v timedatectl >/dev/null || die 'Install systemd before installing Linux dotfiles.'
    command -v systemctl >/dev/null || die 'Install systemd before installing Linux dotfiles.'
  fi
  synchronized=$(timedatectl show -p NTPSynchronized --value 2>/dev/null || true)
  if [[ $synchronized == yes ]]; then
    TIME_SYNC_READY=1
    return 0
  fi
  service=$(time_sync_service || true)
  if [[ -z $service && ${DRY_RUN:-0} != 1 ]]; then
    die 'No NTP service is installed. Install systemd-timesyncd or chrony, then retry the Linux install.'
  fi
  service=${service:-systemd-timesyncd}
  if [[ ${DRY_RUN:-0} == 1 ]]; then
    run sudo systemctl enable --now "$service"
    run sudo systemctl restart "$service"
    TIME_SYNC_READY=1
    return 0
  fi
  command -v sudo >/dev/null || die 'Install sudo before installing Linux dotfiles.'
  run sudo systemctl enable --now "$service"
  run sudo systemctl restart "$service"
  attempt=0
  while ((attempt < 15)); do
    attempt=$((attempt + 1))
    synchronized=$(timedatectl show -p NTPSynchronized --value 2>/dev/null || true)
    if [[ $synchronized == yes ]]; then
      TIME_SYNC_READY=1
      return 0
    fi
    sleep 2
  done
  die "Linux time is not synchronized. Check $service, then retry the install."
}

require_user() {
  [[ $EUID != 0 || ${DRY_RUN:-0} == 1 ]] || die 'Run as your user, without sudo.'
}

check_layout() {
  # Stow mirrors these paths literally; do not silently configure an unused directory.
  local name default
  for name in CONFIG DATA STATE CACHE; do
    case $name in
      CONFIG) default="$target_dir/.config" ;;
      DATA) default="$target_dir/.local/share" ;;
      STATE) default="$target_dir/.local/state" ;;
      CACHE) default="$target_dir/.cache" ;;
    esac
    name="XDG_${name}_HOME"
    [[ -z ${!name:-} || ${!name} == "$default" ]] || die "$name uses a custom location. These packages use the standard home layout."
  done
}

read_packages() {
  local package
  packages=()
  if (($#)); then
    packages=("$@")
  else
    while IFS= read -r package || [[ -n $package ]]; do
      [[ -z $package || $package == \#* ]] || packages+=("$package")
    done <"$DOTFILES_ROOT/deps/stow.txt"
  fi
  for package in "${packages[@]}"; do
    [[ $package =~ ^[a-z][a-z0-9-]*$ && -d $DOTFILES_ROOT/$package/.config ]] || die "Unknown Stow package: $package"
  done
}

check_path() {
  local relative=$1 parent
  case "/$relative/" in
    *'/../'* | *'/./'* | *'//'* | *$'\n'* | *$'\r'* | *$'\t'*) die "Invalid relative path: $relative" ;;
  esac
  case $relative in
    '' | /* | . | .config | .local | .local/share | .local/state | .cache | .ssh | .ssh/* | .gnupg | .gnupg/*)
      die "Refusing broad or credential path: $relative"
      ;;
  esac
  [[ $relative != *'*'* && $relative != *'?'* && $relative != *'['* ]] || die "Use literal paths, not globs: $relative"
  case "$backup_root/" in "$target_dir/$relative/"*) die "Path contains the backups: $relative" ;; esac
  case "$DOTFILES_ROOT/" in "$target_dir/$relative/"*) die "Path contains this checkout: $relative" ;; esac
  parent=$relative
  while [[ $parent == */* ]]; do
    parent=${parent%/*}
    [[ $parent != .config || ${detach_config:-no} != yes ]] || continue
    [[ ! -L $target_dir/$parent ]] || die "Parent is a symlink: $target_dir/$parent"
  done
}

new_backup() {
  [[ -z $backup_dir ]] || return 0
  check_path .local/state/dotfiles/backups/entry
  mkdir -p "$backup_root"
  backup_dir=$(mktemp -d "$backup_root/$(date +%Y%m%d-%H%M%S)-XXXXXX")
  printf '%s\n' "$target_dir" >"$backup_dir/target"
  : >"$backup_dir/paths"
  printf 'Backup: %s\n' "$backup_dir"
}

backup_path() {
  local relative=$1
  [[ -e $target_dir/$relative || -L $target_dir/$relative ]] || return 0
  check_path "$relative"
  new_backup
  mkdir -p "$backup_dir/files/$(dirname -- "$relative")"
  [[ ! -e $backup_dir/files/$relative && ! -L $backup_dir/files/$relative ]] || die "Already backed up: $relative"
  # Record before moving so an interrupted refresh is still restorable.
  printf '%s\n' "$relative" >>"$backup_dir/paths"
  mv -- "$target_dir/$relative" "$backup_dir/files/$relative"
}
