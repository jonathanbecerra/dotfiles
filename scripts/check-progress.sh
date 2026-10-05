#!/usr/bin/env bash
# shellcheck source=scripts/lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT

progress 'Install fixture' printf 'routine output\n' >"$temporary/success"
grep -q '✓ Install fixture' "$temporary/success" || die 'Missing completion output.'
if grep -q 'routine output' "$temporary/success"; then die 'Routine output was not hidden.'; fi
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
printf 'Quiet progress, failure, preview, and foreground checks passed.\n'
