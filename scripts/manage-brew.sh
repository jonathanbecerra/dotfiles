#!/usr/bin/env bash
# shellcheck source=scripts/lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
action=${1:-plan}
(($# <= 1)) || die 'Usage: manage-brew.sh [install|plan|apply]'
case $action in install | plan | apply) ;; *) die 'Choose install, plan, or apply.' ;; esac
require_user
if [[ ${DRY_RUN:-0} != 1 ]]; then
  [[ $(uname -s) == Darwin ]] || die 'Brew setup is for macOS.'
  [[ $target_dir == "$(cd -- "$HOME" && pwd -P)" ]] || die 'Brew operates on this Mac, not DOTFILES_TARGET.'
  command -v brew >/dev/null || die 'Install Homebrew first: https://brew.sh'
fi
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1
brewfile="$DOTFILES_ROOT/brew/Brewfile"
case $action in
  install) run brew bundle install --no-upgrade --file="$brewfile" ;;
  plan)
    if [[ ${DRY_RUN:-0} == 1 ]]; then
      run brew bundle cleanup --formula --cask --file="$brewfile"
    else
      brew bundle list --file="$brewfile" >/dev/null
      # Homebrew returns 1 when cleanup is declined. Closed stdin prevents confirmation.
      status=0
      brew bundle cleanup --formula --cask --file="$brewfile" </dev/null || status=$?
      ((status <= 1)) || exit "$status"
    fi
    printf 'Keep work packages in ~/.config/dotfiles/Brewfile.local before applying.\n'
    ;;
  apply)
    if [[ ${DRY_RUN:-0} == 1 ]]; then
      run brew bundle dump --force --file="$backup_root/<snapshot>/Brewfile"
    else
      brew bundle check --file="$brewfile" || die 'Run make install before pruning Brew.'
      new_backup
      brew bundle dump --force --file="$backup_dir/Brewfile"
    fi
    run brew bundle cleanup --force --formula --cask --file="$brewfile"
    ;;
esac
