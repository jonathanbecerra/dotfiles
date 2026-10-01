#!/usr/bin/env bash
# shellcheck source=scripts/lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
reload_shell=no
case ${1:-} in '') ;; --reload-shell) reload_shell=yes ;; *) die 'Usage: install.sh [--reload-shell]' ;; esac
(($# <= 1)) || die 'Usage: install.sh [--reload-shell]'
require_user
check_layout
[[ ! -L $target_dir/.config || ${DRY_RUN:-0} == 1 ]] || die 'Run make refresh first to replace the existing .config symlink.'
[[ $target_dir == "$(cd -- "$HOME" && pwd -P)" || ${DRY_RUN:-0} == 1 ]] || die 'Full installation targets the current user. DOTFILES_TARGET is for link and refresh checks.'
case $(uname -s) in
  Darwin) bash "$DOTFILES_ROOT/scripts/manage-brew.sh" install ;;
  Linux) bash "$DOTFILES_ROOT/scripts/install-linux.sh" ;;
  *) die 'Use macOS or Linux.' ;;
esac
export PATH="$target_dir/.local/bin:$PATH"
if [[ ${DRY_RUN:-0} != 1 ]]; then
  for tool in git curl stow nvim zsh; do
    command -v "$tool" >/dev/null || die "Install $tool with your OS package manager first."
  done
  # shellcheck disable=SC2119
  read_packages
  stow --simulate --restow --no-folding --dir="$DOTFILES_ROOT" --target="$target_dir" "${packages[@]}" ||
    die 'Config conflicts found. Run make refresh, review the paths, then make refresh action=apply.'
fi
export XDG_CONFIG_HOME="$target_dir/.config" XDG_DATA_HOME="$target_dir/.local/share"
export XDG_STATE_HOME="$target_dir/.local/state" XDG_CACHE_HOME="$target_dir/.cache"
export NVM_DIR="$XDG_DATA_HOME/nvm"
while IFS=$'\t' read -r relative repository commit; do
  [[ -z $relative || $relative == \#* ]] && continue
  check_path ".local/share/$relative"
  destination="$XDG_DATA_HOME/$relative"
  if [[ ${DRY_RUN:-0} != 1 ]]; then
    [[ ! -L $destination ]] || die "Plugin destination is a symlink: $destination"
    [[ ! -e $destination || -d $destination/.git ]] || die "Not a git checkout: $destination"
    if [[ -d $destination/.git ]]; then
      [[ -z $(git -C "$destination" status --porcelain --untracked-files=no) ]] || die "Plugin has local changes: $destination"
      [[ $(git -C "$destination" rev-parse HEAD) != "$commit" ]] || continue
    fi
  fi
  if [[ ! -d $destination/.git ]]; then
    run git clone -q --filter=blob:none "$repository" "$destination"
  fi
  run git -C "$destination" fetch -q --depth 1 "$repository" "$commit"
  run git -C "$destination" checkout -q --detach "$commit"
done <"$DOTFILES_ROOT/deps/plugins.tsv"

node_version=$(<"$DOTFILES_ROOT/.nvmrc")
[[ $node_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die 'Invalid Node version in .nvmrc.'
pnpm_spec=$(<"$DOTFILES_ROOT/deps/nvm/default-packages")
[[ $pnpm_spec =~ ^pnpm@[0-9]+\.[0-9]+\.[0-9]+$ ]] || die 'Invalid pinned pnpm package.'
run install -m 0644 "$DOTFILES_ROOT/deps/nvm/default-packages" "$NVM_DIR/default-packages"
if [[ ${DRY_RUN:-0} != 1 ]]; then
  # NVM probes unset variables and missing Node versions while loading.
  set +u
  # shellcheck source=/dev/null
  source "$NVM_DIR/nvm.sh" --no-use || die 'Could not load NVM.'
fi
run nvm install "$node_version" --skip-default-packages || die 'Node installation failed.'
run nvm alias default "$node_version" || die 'Could not set the default Node version.'
run nvm use --silent "$node_version" || die 'Could not activate Node.'
set -u
run npm install --global "$pnpm_spec"
tools_dir="$XDG_DATA_HOME/nvim/tools"
run mkdir -p "$tools_dir"
run install -m 0644 "$DOTFILES_ROOT/deps/nvim/package.json" "$tools_dir/package.json"
run install -m 0644 "$DOTFILES_ROOT/deps/nvim/package-lock.json" "$tools_dir/package-lock.json"
run npm --prefix "$tools_dir" ci --no-audit --no-fund
bash "$DOTFILES_ROOT/scripts/stow.sh"
if command -v bat >/dev/null; then
  run bat cache --build
elif command -v batcat >/dev/null; then
  run batcat cache --build
fi
if command -v deja >/dev/null; then run deja init zsh; fi
run nvim --headless '+Lazy! restore' +qa
if [[ ${DRY_RUN:-0} == 1 ]]; then
  printf 'Preview complete. No tools or dotfiles were installed.\n'
else
  printf 'Dotfiles installed. Open a new terminal or run exec env -u ZDOTDIR zsh -l. Reload tmux with tmux source-file ~/.tmux.conf.\n'
fi
[[ $reload_shell != yes || ${DRY_RUN:-0} == 1 ]] || exec env -u ZDOTDIR zsh -l
