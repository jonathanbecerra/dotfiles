#!/usr/bin/env bash
# shellcheck source=scripts/lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT

progress 'Install fixture' printf 'routine output\n' >"$temporary/success"
grep -q '✓ Install fixture' "$temporary/success" || die 'Missing completion output.'
if grep -q 'routine output' "$temporary/success"; then die 'Routine output was not hidden.'; fi
[[ $(wc -l <"$temporary/success") -eq 1 ]] || die 'Progress printed duplicate step lines.'
if LC_ALL=C grep -q $'\033' "$temporary/success"; then die 'Progress wrote terminal escapes to a pipe.'; fi
if progress 'Failing fixture' bash -c 'echo failure-detail >&2; exit 7' >"$temporary/failure" 2>&1; then
  die 'A failed command passed.'
else
  [[ $? == 7 ]] || die 'Lost the failed command status.'
fi
grep -q failure-detail "$temporary/failure" || die 'Failure output was hidden.'
DOTFILES_VERBOSE=1 progress Verbose printf 'verbose output\n' >"$temporary/verbose"
grep -q 'verbose output' "$temporary/verbose" || die 'Verbose mode suppressed output.'
DRY_RUN=1 progress Preview touch "$temporary/should-not-exist" >/dev/null
[[ ! -e $temporary/should-not-exist ]] || die 'Preview ran a command.'

foreground_fixture() {
  read -r fixture_answer
  fixture_state=changed
}
fixture_state=original fixture_answer=''
progress 'Foreground fixture' foreground_fixture <<<'ready' >/dev/null
[[ $fixture_state == changed && $fixture_answer == ready ]] || die 'Progress lost foreground input or shell state.'

sudo() {
  case "$*" in
    '-n -v') return 1 ;;
    '-v') printf 'password-prompt\n' ;;
    *) die 'Unexpected sudo command in fixture.' ;;
  esac
}
authorize_sudo >"$temporary/auth"
grep -q 'Dotfiles needs sudo' "$temporary/auth" || die 'Sudo prompt has no explanation.'
[[ $(tail -n 1 "$temporary/auth") == password-prompt ]] || die 'Explanation did not precede sudo authentication.'
sudo() { [[ $* == '-n -v' ]]; }
authorize_sudo >"$temporary/auth"
[[ ! -s $temporary/auth ]] || die 'Cached sudo access caused an unnecessary prompt.'
sudo() { return 23; }
if authorize_sudo >"$temporary/auth"; then die 'Failed sudo authentication passed.'; fi
DRY_RUN=1 authorize_sudo >"$temporary/auth"
[[ ! -s $temporary/auth ]] || die 'Preview tried to authenticate.'

# Load only the plugin function; never run the real installer in these checks.
sed -n '/^install_plugin()/,/^}/p' "$DOTFILES_ROOT/scripts/install.sh" >"$temporary/plugin-fixture.sh"
# shellcheck source=/dev/null
source "$temporary/plugin-fixture.sh"
git() {
  printf '%s\n' "$*" >>"$temporary/git-calls"
  printf 'remote: download noise\n' >&2
  if [[ $* == *fetch* && ${fixture_git_fail:-no} == yes ]]; then return 7; fi
}
progress 'Plugin fixture' install_plugin fixture-repo fixture-commit "$temporary/plugin" >"$temporary/plugin-output" 2>&1
[[ $(wc -l <"$temporary/git-calls") -eq 3 ]] || die 'Plugin install missed a Git step.'
if grep -q 'remote:' "$temporary/plugin-output"; then die 'Git progress escaped the quiet install.'; fi
: >"$temporary/git-calls"
if fixture_git_fail=yes progress 'Plugin fixture' install_plugin fixture-repo fixture-commit "$temporary/plugin" >"$temporary/plugin-output" 2>&1; then
  die 'A failed plugin fetch passed.'
fi
[[ $(wc -l <"$temporary/git-calls") -eq 2 ]] || die 'Plugin checkout ran after a failed fetch.'
grep -q 'remote:' "$temporary/plugin-output" || die 'Git failure details were hidden.'
progress 'Stow fixture' bash -c 'echo "WARNING: in simulation mode so not modifying filesystem." >&2' >"$temporary/stow" 2>&1
if grep -q WARNING "$temporary/stow"; then die 'Successful Stow simulation was not quiet.'; fi
printf 'Progress, sudo prompts, plugin failures, previews, and foreground checks passed.\n'
