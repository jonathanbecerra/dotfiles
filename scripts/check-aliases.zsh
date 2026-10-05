#!/usr/bin/env zsh
# Stub every Docker call. No daemon, containers, or user data are touched.
set -eu
root=${0:A:h:h}
source "$root/zsh/.config/zsh/aliases.zsh" || true
temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT
calls=$temporary/calls
answer=no
scenario=normal
fail() { print -u2 -- "$*"; exit 1; }
read() { [[ $answer == yes ]]; }
docker() {
  print -r -- "$*" >>"$calls"
  case "$*" in
    'context show') print fixture ;;
    'ps -q')
      [[ $scenario != daemon-error ]] || return 69
      print -l one two
      ;;
    'container inspect --format {{.Id}} -- demo') print id-demo ;;
    'container inspect --format {{.Image}} id-demo') print image-demo ;;
    'container inspect --format {{range .Mounts}}'*) print -l owned shared ;;
    'ps -aq --filter volume=owned')
      [[ $scenario != inspect-error ]] || return 70
      ;;
    'ps -aq --filter volume=shared' | 'ps -aq --filter ancestor=image-demo') print another-container ;;
    'stop one two' | 'rm -f id-demo' | 'volume rm owned' | 'system prune --all --force' | 'volume prune --all --force') ;;
    *) print -u2 -- "Unexpected Docker command: $*"; return 90 ;;
  esac
}

: >"$calls"
if dtd >/dev/null; then fail 'Teardown ignored cancellation.'; fi
[[ $(<"$calls") == 'context show' ]] || fail 'Cancellation mutated Docker.'
answer=yes
: >"$calls"
dtd >/dev/null
[[ $(<"$calls") == *'stop one two'*'system prune --all --force'*'volume prune --all --force'* ]] || fail 'Global teardown omitted named volumes or ran out of order.'

: >"$calls"
scenario=daemon-error
if dstall >/dev/null; then fail 'A Docker daemon failure was treated as an empty list.'; fi
[[ $(<"$calls") == 'ps -q' ]] || fail 'Docker stop ran after a listing failure.'
scenario=normal
: >"$calls"
dts demo >/dev/null
[[ $(<"$calls") == *'rm -f id-demo'*'volume rm owned'* ]] || fail 'Scoped teardown missed its target.'
[[ $(<"$calls") != *'volume rm shared'* && $(<"$calls") != *'image rm'* && $(<"$calls") != *'network '* ]] || fail 'Scoped teardown removed shared resources.'
scenario=inspect-error
: >"$calls"
if dts demo >/dev/null; then fail 'Scoped teardown ignored a volume inspection failure.'; fi
[[ $(<"$calls") != *'volume rm'* ]] || fail 'A failed check allowed volume deletion.'

[[ $(define dpt) == *'docker port'* ]] || fail 'define did not show a function.'
[[ $(define cl) == *clear* ]] || fail 'define did not show an alias.'
(( ! ${+aliases[grep]} && ! ${+aliases[rgrep]} )) || fail 'grep or rgrep was aliased.'
[[ ${aliases[dcup]} == 'dc up -d' ]] || fail 'Compose shortcuts bypass the selected Compose command.'
print 'Alias definitions, Docker cancellation, shared-resource guards, and failure checks passed.'
