# Platform detection
IS_MACOS=false
IS_LINUX=false

case "$OSTYPE" in
darwin*) IS_MACOS=true ;;
linux*) IS_LINUX=true ;;
esac

if $IS_LINUX; then
  sudo pacman -S --needed - <packages
fi

if $IS_MACOS; then
  brew install $(<packages)
fi
