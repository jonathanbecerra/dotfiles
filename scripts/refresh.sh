#!/usr/bin/env bash
# shellcheck source=scripts/lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
action=${1:-plan}
if (($#)); then shift; fi
case $action in
  plan | apply) ;;
  restore)
    (($# == 1)) || die 'Usage: refresh.sh restore BACKUP'
    saved_dir=$(cd -- "$1" && pwd -P)
    [[ $saved_dir == "$backup_root/"* && -f $saved_dir/target && -f $saved_dir/paths ]] || die 'Choose a dotfiles backup directory.'
    [[ $(<"$saved_dir/target") == "$target_dir" ]] || die 'This backup belongs to a different home directory.'
    [[ ! -f $saved_dir/restored ]] || {
      printf 'This backup has already been restored.\n'
      exit 0
    }
    scope="$saved_dir/paths"
    [[ ! -f $saved_dir/scope ]] || scope="$saved_dir/scope"
    present="$saved_dir/paths"
    [[ ! -f $saved_dir/present ]] || present="$saved_dir/present"
    paths=()
    while IFS= read -r relative || [[ -n $relative ]]; do
      # The whole .config link was archived; its old target was never changed.
      [[ ! -f $saved_dir/config-scope || $relative != .config/* ]] || continue
      check_path "$relative"
      paths+=("$relative")
    done <"$scope"
    require_user
    for relative in "${paths[@]+"${paths[@]}"}"; do
      if [[ -f $saved_dir/restored-paths ]] && grep -Fxq -- "$relative" "$saved_dir/restored-paths"; then continue; fi
      # A completed move or a failed refresh may have left the original in place.
      if grep -Fxq -- "$relative" "$present" && [[ ! -e $saved_dir/files/$relative && ! -L $saved_dir/files/$relative ]]; then continue; fi
      printf 'Restore: %s\n' "$target_dir/$relative"
      if [[ ${DRY_RUN:-0} != 1 ]]; then
        backup_path "$relative"
        if [[ -e $saved_dir/files/$relative || -L $saved_dir/files/$relative ]]; then
          mkdir -p "$target_dir/$(dirname -- "$relative")"
          mv -- "$saved_dir/files/$relative" "$target_dir/$relative"
        fi
        printf '%s\n' "$relative" >>"$saved_dir/restored-paths"
      fi
    done
    if [[ -e $saved_dir/config || -L $saved_dir/config ]]; then
      printf 'Restore: %s/.config\n' "$target_dir"
      if [[ ${DRY_RUN:-0} != 1 ]]; then
        new_backup
        touch "$backup_dir/config-scope"
        if [[ -e $target_dir/.config || -L $target_dir/.config ]]; then
          mv -- "$target_dir/.config" "$backup_dir/config"
        fi
        mv -- "$saved_dir/config" "$target_dir/.config"
      fi
    fi
    [[ ${DRY_RUN:-0} == 1 ]] || touch "$saved_dir/restored"
    exit 0
    ;;
  *) die 'Usage: refresh.sh [plan|apply] [--extra-paths FILE] | restore BACKUP' ;;
esac
extra_paths=
while (($#)); do
  case $1 in
    --extra-paths)
      (($# >= 2)) || die 'Missing path file.'
      extra_paths=$2
      shift 2
      ;;
    *) die "Unknown option: $1" ;;
  esac
done
check_layout
detach_config=no
config_source=
if [[ -L $target_dir/.config ]]; then
  detach_config=yes
  if [[ -d $target_dir/.config ]]; then
    config_source=$(cd -- "$target_dir/.config" && pwd -P)
  else
    [[ ! -e $target_dir/.config ]] || die '.config points to a file, not a directory.'
  fi
fi
# shellcheck disable=SC2119
read_packages
paths=()
add_path() {
  local relative=$1 existing
  check_path "$relative"
  [[ $detach_config != yes || $relative != .config/*/* ]] || die 'With a symlinked .config, select the whole app directory in the extra path file.'
  for existing in "${paths[@]+"${paths[@]}"}"; do
    [[ $relative != "$existing" ]] || return 0
    [[ $relative != "$existing/"* && $existing != "$relative/"* ]] || die "Overlapping reset paths: $existing and $relative"
  done
  paths+=("$relative")
}
shopt -s nullglob
for package in "${packages[@]}"; do
  for entry in "$DOTFILES_ROOT/$package"/.[!.]*; do
    if [[ ${entry##*/} == .config ]]; then
      for config in "$entry"/*; do add_path ".config/${config##*/}"; done
    else
      add_path "${entry##*/}"
    fi
  done
done
for list in "$DOTFILES_ROOT/config/refresh-paths.txt" ${extra_paths:+"$extra_paths"}; do
  [[ -f $list ]] || die "Path file not found: $list"
  while IFS= read -r relative || [[ -n $relative ]]; do
    [[ -z $relative || $relative == \#* ]] || add_path "$relative"
  done <"$list"
done

printf 'Refresh target: %s\n' "$target_dir"
[[ $detach_config != yes ]] || printf 'Back up the .config symlink; keep unrelated entries linked to %s.\n' "${config_source:-its missing target}"
for relative in "${paths[@]}"; do
  [[ -e $target_dir/$relative || -L $target_dir/$relative ]] || continue
  printf 'Back up: %s\n' "$target_dir/$relative"
done
if [[ $action == apply && ${DRY_RUN:-0} != 1 ]]; then
  require_user
  new_backup
  # Record absent paths too so restore removes new startup files after installation.
  printf '%s\n' "${paths[@]}" >"$backup_dir/scope"
  : >"$backup_dir/present"
  for relative in "${paths[@]}"; do
    if [[ -e $target_dir/$relative || -L $target_dir/$relative ]]; then
      printf '%s\n' "$relative" >>"$backup_dir/present"
    fi
  done
  if [[ $detach_config == yes ]]; then
    touch "$backup_dir/config-scope"
    mv -- "$target_dir/.config" "$backup_dir/config"
    mkdir "$target_dir/.config"
    if [[ -n $config_source ]]; then
      for entry in "$config_source"/* "$config_source"/.[!.]* "$config_source"/..?*; do
        managed=no
        for relative in "${paths[@]}"; do
          [[ $relative != ".config/${entry##*/}" ]] || managed=yes
        done
        [[ $managed == yes ]] || ln -s "$entry" "$target_dir/.config/${entry##*/}"
      done
    fi
  fi
  for relative in "${paths[@]}"; do
    [[ $detach_config != yes || $relative != .config/* ]] || continue
    backup_path "$relative"
  done
  printf 'Run make install from the dotfiles checkout, then exec env -u ZDOTDIR zsh -l.\n'
else
  printf 'Preview only. Use refresh.sh apply to move these paths into a backup.\n'
fi
