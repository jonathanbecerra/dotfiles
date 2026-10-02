# Dotfiles

A small shell and editor setup for macOS and Linux. It gives both machines the
same Rose Pine look, Ghostty, aliases, Git config, tmux, Neovim, and CLI tools.

## Quick start

```sh
git clone git@github.com:jonathanbecerra/dotfiles.git
cd dotfiles
make install
```

`make install` installs the tools declared here and links the configs into your
home directory with Stow. On macOS it uses Homebrew, including Ghostty and the
JetBrains Mono Nerd Font; on Linux it uses apt and the pinned local binaries.
Linux installs also make sure the system clock is synchronized before contacting
apt. Node is managed by NVM, and Neovim loads its plugins on the first start.
The install reloads Zsh after Stow completes. Run `make reload-zsh` after later
config-only changes.

If the tools are already installed, just link the configs:

```sh
make stow
```

Stow stops when an existing file would be overwritten. Move that file aside or
run `make refresh` first.

## Moving an existing machine

Keep the old setup until you have checked the new shell. First preview the
paths, then apply the move:

```sh
make refresh
make refresh action=apply
make install
```

The refresh makes a timestamped backup under
`~/.local/state/dotfiles/backups/`. Undo it with the backup path it prints:

```sh
make restore backup=/path/to/backup
```

It only handles managed shell, editor, and CLI paths. SSH keys, history, GPG
keys, existing Node versions, and unrelated config stay where they are.

## Useful commands

```sh
make check                    # validate the checkout
make prune-brew               # preview Homebrew cleanup
make prune-brew action=apply  # save a Brewfile snapshot, then clean up
```

Put work-only Homebrew packages in `~/.config/dotfiles/Brewfile.local` before
pruning. Keep machine-specific settings in `.zshrc.local`,
`.tmux.conf.local`, `~/.config/nvim-local.lua`, and local Git config. Never
commit credentials or tokens here.

`DRY_RUN=1 make <target>` previews supported commands. This repository can be
used on its own or as the `dotfiles/` submodule in the VPS project.
