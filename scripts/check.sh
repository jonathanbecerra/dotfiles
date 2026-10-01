#!/usr/bin/env bash
# shellcheck source=scripts/lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
cd "$DOTFILES_ROOT"
[[ -s apt/packages.txt && -s apt/binaries.tsv ]] || die 'Missing Linux dependency manifests.'
awk -F '\t' '$1 !~ /^#/ && NF != 5 { exit 1 }' apt/binaries.tsv || die 'Invalid pinned binary manifest.'
if [[ ${DRY_RUN:-0} == 1 ]]; then
  printf 'Check Bash/zsh syntax, ShellCheck, shfmt, JSON, Git config, and refresh/restore in temporary directories.\n'
  exit 0
fi
for tool in bash shellcheck shfmt jq zsh stow; do
  command -v "$tool" >/dev/null || die "Install $tool to run dotfiles checks."
done
files=(scripts/*.sh tmux/.config/tmux/choose-session.sh)
for file in "${files[@]}"; do bash -n "$file"; done
shellcheck -x "${files[@]}"
shfmt -d -i 2 -ci "${files[@]}"
for file in zsh/.zshenv zsh/.p10k.zsh zsh/.config/zsh/.zprofile zsh/.config/zsh/.zshrc zsh/.config/zsh/aliases.zsh; do zsh -n "$file"; done
jq -e . glow/.config/glow/styles/rose-pine.json nvim/.config/nvim/lazy-lock.json \
  deps/nvim/package.json deps/nvim/package-lock.json >/dev/null
git config --file git/.config/git/config --list >/dev/null
bash scripts/check-refresh.sh
printf 'Dotfiles checks passed.\n'
