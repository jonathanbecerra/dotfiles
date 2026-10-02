#!/usr/bin/env bash
# shellcheck source=scripts/lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

[[ $(uname -s) == Linux ]] || die 'Linux dependencies are only used on Linux.'

read_apt_packages() {
  local file="$DOTFILES_ROOT/apt/packages.txt" package
  apt_packages=()
  while IFS= read -r package || [[ -n $package ]]; do
    package=${package%%#*}
    package="${package#"${package%%[![:space:]]*}"}"
    package="${package%"${package##*[![:space:]]}"}"
    [[ -z $package ]] && continue
    [[ $package =~ ^[a-z0-9][a-z0-9+._-]*$ ]] || die "Invalid apt package: $package"
    apt_packages+=("$package")
  done <"$file"
}

binary_destination() {
  case $1 in
    nvim) printf '%s/.local/bin/nvim\n' "$target_dir" ;;
    superfile) printf '%s/.local/bin/spf\n' "$target_dir" ;;
    lua-language-server) printf '%s/.local/bin/lua-language-server\n' "$target_dir" ;;
    jetbrains-mono) printf '%s/.local/share/fonts/jetbrains-mono\n' "$target_dir" ;;
    *) printf '%s/.local/bin/%s\n' "$target_dir" "$1" ;;
  esac
}

preview_binaries() {
  local tool arch url checksum member
  while IFS=$'\t' read -r tool arch url checksum member; do
    [[ -z $tool || $tool == \#* ]] && continue
    [[ $arch == all || $arch == "$(uname -m)" ]] || continue
    printf '  %s -> %s\n' "$tool" "$(binary_destination "$tool")"
  done <"$DOTFILES_ROOT/apt/binaries.tsv"
}

install_binaries() {
  local architecture tool arch url checksum member found marker destination version font_dir
  local temporary="$1"
  architecture=$(uname -m)
  install -d -m 0755 "$target_dir/.local/bin" "$target_dir/.local/state/dotfiles/binaries"
  while IFS=$'\t' read -r tool arch url checksum member; do
    [[ -z $tool || $tool == \#* ]] && continue
    [[ $arch == all || $arch == "$architecture" ]] || continue
    found=yes
    marker="$target_dir/.local/state/dotfiles/binaries/$tool"
    destination=$(binary_destination "$tool")
    if [[ -f $marker && $(<"$marker") == "$checksum" ]]; then
      case $tool in
        jetbrains-mono) [[ -d $destination ]] && continue ;;
        *) [[ -x $destination ]] && continue ;;
      esac
    fi
    printf 'Installing %s\n' "$tool"
    curl --fail --silent --show-error --location --retry 3 "$url" -o "$temporary/archive"
    printf '%s  %s\n' "$checksum" "$temporary/archive" | sha256sum --check --status
    case $tool in
      nvim)
        version=${url%/*}
        version=${version##*/}
        install_dir="$target_dir/.local/share/nvim/releases/$version"
        install -d -m 0755 "$install_dir"
        tar -xzf "$temporary/archive" -C "$install_dir" --strip-components=1 "$member"
        ln -sfn "$install_dir/bin/nvim" "$destination"
        ;;
      lua-language-server)
        version=${url##*/lua-language-server-}
        version=${version%%-linux-*}
        install_dir="$target_dir/.local/share/lua-language-server/$version"
        install -d -m 0755 "$install_dir"
        tar -xzf "$temporary/archive" -C "$install_dir"
        cat >"$temporary/lua-language-server" <<EOF
#!/usr/bin/env bash
exec "$install_dir/bin/lua-language-server" "\$@"
EOF
        install -m 0755 "$temporary/lua-language-server" "$destination"
        ;;
      superfile)
        tar -xOf "$temporary/archive" "$member" >"$temporary/binary"
        install -m 0755 "$temporary/binary" "$destination"
        ;;
      jetbrains-mono)
        font_dir="$destination"
        install -d -m 0755 "$font_dir"
        unzip -jo "$temporary/archive" 'JetBrainsMonoNerdFontMono-*.ttf' 'OFL.txt' -d "$font_dir"
        chmod 0644 "$font_dir"/*
        command -v fc-cache >/dev/null && fc-cache -f "$font_dir"
        ;;
      *)
        if [[ $member == - ]]; then
          install -m 0755 "$temporary/archive" "$destination"
        else
          tar -xOf "$temporary/archive" "$member" >"$temporary/binary"
          install -m 0755 "$temporary/binary" "$destination"
        fi
        ;;
    esac
    printf '%s\n' "$checksum" >"$marker"
  done <"$DOTFILES_ROOT/apt/binaries.tsv"
  [[ ${found:-} == yes ]] || die "No pinned Linux binaries found for $architecture."
}

read_apt_packages
ensure_time_sync
wait_for_apt
if [[ ${DRY_RUN:-0} == 1 ]]; then
  run sudo apt-get update
  run sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${apt_packages[@]}"
  preview_binaries
  exit 0
fi

command -v sudo >/dev/null || die 'Install sudo before installing Linux dotfiles.'
command -v apt-get >/dev/null || die 'This Linux host needs apt-get.'
run sudo apt-get update
wait_for_apt
run sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${apt_packages[@]}"

temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT
install_binaries "$temporary"
