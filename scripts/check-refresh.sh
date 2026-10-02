#!/usr/bin/env bash
# shellcheck source=scripts/lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
if [[ ${DRY_RUN:-0} == 1 ]]; then
  printf 'Check refresh, Stow, restore, and dry runs in a disposable home directory.\n'
  exit 0
fi
temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT
cp -R "$DOTFILES_ROOT" "$temporary/standalone"
repo="$temporary/standalone"
export DOTFILES_TARGET="$temporary/home with spaces"
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
mkdir -p "$DOTFILES_TARGET/.config/nvim" "$DOTFILES_TARGET/.config/unrelated" \
  "$DOTFILES_TARGET/.local/share/nvim" "$DOTFILES_TARGET/.local/state/nvim" \
  "$DOTFILES_TARGET/.cache/nvim" "$DOTFILES_TARGET/.ssh"
printf 'old editor\n' >"$DOTFILES_TARGET/.config/nvim/init.lua"
printf 'old plugin\n' >"$DOTFILES_TARGET/.local/share/nvim/plugin"
printf 'keep\n' >"$DOTFILES_TARGET/.config/unrelated/config"
printf 'private\n' >"$DOTFILES_TARGET/.ssh/key"
printf 'shell\n' >"$temporary/old-zshrc"
ln -s "$temporary/old-zshrc" "$DOTFILES_TARGET/.zshrc"
ln -s "$temporary/missing" "$DOTFILES_TARGET/.zprofile"

bash "$repo/scripts/refresh.sh" plan >/dev/null
DRY_RUN=1 bash "$repo/scripts/refresh.sh" apply >/dev/null
[[ -f $DOTFILES_TARGET/.config/nvim/init.lua && ! -d $DOTFILES_TARGET/.local/state/dotfiles ]] || die 'Preview changed the target.'
log=$(bash "$repo/scripts/refresh.sh" apply)
saved_dir=$(printf '%s\n' "$log" | sed -n 's/^Backup: //p')
[[ -f $saved_dir/files/.config/nvim/init.lua && ! -e $DOTFILES_TARGET/.config/nvim ]] || die 'Refresh did not archive Neovim.'
[[ -L $saved_dir/files/.zprofile && -f $temporary/old-zshrc ]] || die 'Refresh followed a symlink.'
[[ -f $DOTFILES_TARGET/.ssh/key && -f $DOTFILES_TARGET/.config/unrelated/config ]] || die 'Refresh touched unrelated files.'
bash "$repo/scripts/refresh.sh" apply >/dev/null
bash "$repo/scripts/stow.sh" >/dev/null 2>&1
bash "$repo/scripts/stow.sh" >/dev/null 2>&1
[[ -L $DOTFILES_TARGET/.config/nvim/init.lua && -f $DOTFILES_TARGET/.tmux.conf ]] || die 'Stow links are incomplete.'
DRY_RUN=1 bash "$repo/scripts/refresh.sh" restore "$saved_dir" >/dev/null
[[ -L $DOTFILES_TARGET/.config/nvim/init.lua ]] || die 'Restore preview changed the target.'
log=$(bash "$repo/scripts/refresh.sh" restore "$saved_dir")
replaced_dir=$(printf '%s\n' "$log" | sed -n 's/^Backup: //p')
[[ $(<"$DOTFILES_TARGET/.config/nvim/init.lua") == 'old editor' ]] || die 'Restore lost the old editor config.'
[[ -L $replaced_dir/files/.config/nvim/init.lua ]] || die 'Restore discarded the new config.'
[[ $(readlink "$DOTFILES_TARGET/.zshrc") == "$temporary/old-zshrc" && -L $DOTFILES_TARGET/.zprofile ]] || die 'Restore lost symlinks.'
[[ ! -e $DOTFILES_TARGET/.zshenv && ! -L $DOTFILES_TARGET/.zshenv ]] || die 'Restore left the new zsh startup redirect installed.'
bash "$repo/scripts/refresh.sh" restore "$saved_dir" >/dev/null
[[ $(<"$DOTFILES_TARGET/.config/nvim/init.lua") == 'old editor' ]] || die 'Repeated restore moved the restored files.'

printf '../outside\n' >"$temporary/paths"
if bash "$repo/scripts/refresh.sh" apply --extra-paths "$temporary/paths" >/dev/null 2>&1; then die 'Accepted parent traversal.'; fi
printf '.config\n' >"$temporary/paths"
if bash "$repo/scripts/refresh.sh" apply --extra-paths "$temporary/paths" >/dev/null 2>&1; then die 'Accepted an entire config directory.'; fi
mkdir -p "$temporary/symlink-home" "$temporary/shared-config/nvim" "$temporary/shared-config/work"
printf 'old\n' >"$temporary/shared-config/nvim/init.lua"
printf 'keep\n' >"$temporary/shared-config/work/settings"
ln -s "$temporary/shared-config" "$temporary/symlink-home/.config"
log=$(DOTFILES_TARGET="$temporary/symlink-home" bash "$repo/scripts/refresh.sh" apply)
linked_backup=$(printf '%s\n' "$log" | sed -n 's/^Backup: //p')
[[ ! -L $temporary/symlink-home/.config && -L $temporary/symlink-home/.config/work ]] || die 'Did not detach the config link.'
[[ -f $temporary/shared-config/nvim/init.lua && ! -e $temporary/symlink-home/.config/nvim ]] || die 'Changed the old config checkout.'
DOTFILES_TARGET="$temporary/symlink-home" bash "$repo/scripts/stow.sh" >/dev/null 2>&1
DOTFILES_TARGET="$temporary/symlink-home" bash "$repo/scripts/refresh.sh" restore "$linked_backup" >/dev/null
[[ -L $temporary/symlink-home/.config && -f $temporary/symlink-home/.config/work/settings ]] || die 'Did not restore the original config link.'
mkdir -p "$temporary/shared-data" "$DOTFILES_TARGET/.local"
mv "$DOTFILES_TARGET/.local/share" "$temporary/original-share"
ln -s "$temporary/shared-data" "$DOTFILES_TARGET/.local/share"
if bash "$repo/scripts/refresh.sh" apply >/dev/null 2>&1; then die 'Accepted a symlinked data parent.'; fi

mkdir -p "$temporary/failing-bin" "$temporary/failure-home/.config/nvim" \
  "$temporary/failure-home/.local/share/nvim" "$temporary/failure-home/.cache/nvim"
printf 'config\n' >"$temporary/failure-home/.config/nvim/init.lua"
printf 'cache\n' >"$temporary/failure-home/.cache/nvim/keep"
cat >"$temporary/failing-bin/mv" <<'SH'
#!/bin/sh
case "$2" in */.local/share/nvim) exit 23 ;; esac
exec /bin/mv "$@"
SH
chmod +x "$temporary/failing-bin/mv"
if log=$(DOTFILES_TARGET="$temporary/failure-home" PATH="$temporary/failing-bin:$PATH" bash "$repo/scripts/refresh.sh" apply); then
  die 'The failure check did not interrupt refresh.'
fi
failed_backup=$(printf '%s\n' "$log" | sed -n 's/^Backup: //p')
DOTFILES_TARGET="$temporary/failure-home" bash "$repo/scripts/refresh.sh" restore "$failed_backup" >/dev/null
[[ -f $temporary/failure-home/.config/nvim/init.lua && -f $temporary/failure-home/.cache/nvim/keep ]] || die 'Restore lost untouched files after a failed refresh.'

mkdir -p "$temporary/bin" "$temporary/dry-home"
for tool in brew git curl npm nvm nvim stow bat batcat sudo; do
  # shellcheck disable=SC2016
  printf '#!/bin/sh\nprintf "Unexpected tool call: %%s\\n" "$0" >&2\nexit 99\n' >"$temporary/bin/$tool"
  chmod +x "$temporary/bin/$tool"
done
for script in install stow refresh manage-brew check; do
  DRY_RUN=1 DOTFILES_TARGET="$temporary/dry-home" PATH="$temporary/bin:$PATH" \
    bash "$repo/scripts/$script.sh" >/dev/null
done
DRY_RUN=1 DOTFILES_TARGET="$temporary/dry-home" PATH="$temporary/bin:$PATH" \
  bash "$repo/scripts/manage-brew.sh" apply >/dev/null
[[ -z $(ls -A "$temporary/dry-home") ]] || die 'Dry run wrote to the target.'
printf 'Standalone refresh, repeat Stow, restore, path guards, and dry runs passed.\n'
