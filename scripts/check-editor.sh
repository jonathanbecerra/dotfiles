#!/usr/bin/env bash
# shellcheck source=scripts/lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
require_user
step() {
  printf '%s\n' "$1"
  shift
  run "$@"
}
if [[ ${DRY_RUN:-0} == 1 ]]; then
  printf 'Download pinned Neovim and plugins into a temporary directory, then check editor startup and tools.\n'
  exit 0
fi
command -v npm >/dev/null || die 'Install Node.js and npm to check the editor tools.'
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT
export XDG_CONFIG_HOME="$temporary/config" XDG_DATA_HOME="$temporary/data"
export XDG_STATE_HOME="$temporary/state" XDG_CACHE_HOME="$temporary/cache"
tools_dir="$XDG_DATA_HOME/nvim/tools"
mkdir -p "$XDG_CONFIG_HOME/nvim" "$XDG_DATA_HOME/nvim/lazy" "$tools_dir"
cp "$DOTFILES_ROOT/nvim/.config/nvim/lazy-lock.json" "$XDG_CONFIG_HOME/nvim/lazy-lock.json"
cp "$DOTFILES_ROOT/deps/nvim/package.json" "$DOTFILES_ROOT/deps/nvim/package-lock.json" "$tools_dir/"
step 'Install locked Neovim tools' npm --prefix "$tools_dir" ci --no-audit --no-fund
for tool in bash-language-server yaml-language-server vscode-json-language-server stylua; do
  [[ -x $tools_dir/node_modules/.bin/$tool ]] || die "Neovim tool is missing: $tool"
done
read -r repository commit < <(awk -F '\t' '$1 == "nvim/lazy/lazy.nvim" { print $2, $3 }' "$DOTFILES_ROOT/deps/plugins.tsv")
step 'Clone lazy.nvim' git clone -q --filter=blob:none "$repository" "$XDG_DATA_HOME/nvim/lazy/lazy.nvim"
step 'Fetch pinned lazy.nvim commit' git -C "$XDG_DATA_HOME/nvim/lazy/lazy.nvim" fetch -q --depth 1 "$repository" "$commit"
git -C "$XDG_DATA_HOME/nvim/lazy/lazy.nvim" checkout -q --detach FETCH_HEAD
case "$(uname -s)" in
  Linux) architecture=$(uname -m) ;;
  Darwin) architecture="macos-$(uname -m)" ;;
  *)
    printf 'Editor checks support Linux and macOS.\n' >&2
    exit 1
    ;;
esac
# Use the pinned build without replacing the installed editor.
read -r url checksum member < <(awk -F '\t' -v arch="$architecture" '$1 == "nvim" && $2 == arch {print $3, $4, $5}' "$DOTFILES_ROOT/apt/binaries.tsv")
step 'Download pinned Neovim' curl -fsSL --retry 3 "$url" -o "$temporary/nvim.tar.gz"
if [[ $(uname -s) == Linux ]]; then
  printf '%s  %s\n' "$checksum" "$temporary/nvim.tar.gz" | sha256sum -c >/dev/null
else
  printf '%s  %s\n' "$checksum" "$temporary/nvim.tar.gz" | shasum -a 256 -c >/dev/null
fi
tar -xzf "$temporary/nvim.tar.gz" -C "$temporary"
export PATH="$temporary/$member/bin:$PATH"
step 'Restore Neovim plugins' nvim --headless -u "$DOTFILES_ROOT/nvim/.config/nvim/init.lua" '+Lazy! restore' +qa
check_nvim() {
  nvim --headless -u "$DOTFILES_ROOT/nvim/.config/nvim/init.lua" \
    "+lua local ok, err = pcall(function() $1 end); if not ok then vim.api.nvim_err_writeln(tostring(err)); vim.cmd('cquit 1') end" +qa
}
step 'Check Lualine config' check_nvim \
  'vim.wait(2500); assert(vim.fn.exists(":LualineNotices") == 0, "lualine reported configuration notices")'
step 'Check Neovim tool PATH' check_nvim \
  'assert(vim.fn.executable("bash-language-server") == 1 and vim.fn.executable("yaml-language-server") == 1 and vim.fn.executable("vscode-json-language-server") == 1 and vim.fn.executable("stylua") == 1, "Neovim tool PATH is incomplete")'
step 'Check JSON and YAML schemas' check_nvim \
  'assert(next(vim.lsp.config.yamlls.settings.yaml.schemas), "YAML schemas are missing"); assert(#vim.lsp.config.jsonls.settings.json.schemas > 0, "JSON schemas are missing")'
