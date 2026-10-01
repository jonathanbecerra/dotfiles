#!/usr/bin/env bash
# shellcheck source=scripts/lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
require_user
check_layout
read_packages "$@"
if [[ ${DRY_RUN:-0} != 1 ]]; then
  [[ ! -L $target_dir/.config ]] || die 'The target .config directory is a symlink. Run make refresh before stowing.'
  command -v stow >/dev/null || die 'Install GNU Stow first.'
fi
run stow --simulate --restow --no-folding --dir="$DOTFILES_ROOT" --target="$target_dir" "${packages[@]}"
run stow --restow --no-folding --dir="$DOTFILES_ROOT" --target="$target_dir" "${packages[@]}"
