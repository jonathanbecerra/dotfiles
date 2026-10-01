[[ $OSTYPE == darwin* ]] || return
for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [[ ! -x $brew_bin ]] || { eval "$("$brew_bin" shellenv)"; break; }
done
unset brew_bin
