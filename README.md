# Dotfiles

This directory is the portable user environment. It owns shell, Git, tmux,
Neovim, terminal, and CLI configuration, plus the tools needed by those
configs. It is separate from the VPS setup: it does not configure users, SSH,
firewalls, Docker, or services.

Keep this checkout in a permanent location. Stow creates live links from it
into `$HOME`, so deleting or replacing the checkout breaks the linked files.
The directory can be copied into its own repository and used there without
the rest of the VPS project.

## The normal order

Run these commands from this directory:

```sh
DRY_RUN=1 make install   # preview
make install             # install tools and link configs
exec env -u ZDOTDIR zsh -l
```

The first command is optional but useful on a new machine. `make install`
installs the declared tools, pinned NVM and Node version, Neovim plugins, and
shell plugins, then links the configs with Stow. It never removes packages.
Existing Stow conflicts stop the install instead of overwriting files.

On Linux, `make install` reads `apt/packages.txt` and installs the pinned
releases in `apt/binaries.tsv` into `~/.local/bin` using `sudo`. It needs an
apt-based system, sudo, and an internet connection. The VPS host manifest in
the parent repository is separate. On macOS, install Homebrew and the Command
Line Tools; `brew/Brewfile` supplies the user tools there.

## Moving an existing machine to these files

Use a fresh terminal outside tmux and keep the old checkout until the move is
complete:

```sh
make refresh                 # preview paths that will move
make refresh action=apply   # make a timestamped backup and move them
make install
exec env -u ZDOTDIR zsh -l
```

Refresh stores the backup under
`~/.local/state/dotfiles/backups/`. It covers old shell startup files,
managed configs, and Neovim data, state, and cache. It leaves SSH keys, shell
history, GPG keys, existing Node versions, and unrelated configs alone. A
custom path can be added explicitly:

```sh
make refresh paths=/path/to/old-shell-paths.txt
make refresh action=apply paths=/path/to/old-shell-paths.txt
```

Old shell files are never sourced to discover paths.

If `~/.config` is a symlink into an older checkout, refresh backs up that link,
creates a real directory, and keeps unrelated entries linked to their old
locations. Keep the old checkout until those links are no longer needed.

## Undo a refresh

Use the exact backup path printed by refresh:

```sh
make restore backup=/path/printed/by/refresh
exec env -u ZDOTDIR zsh -l
```

Restore saves any replacement files before putting the old files back. It
restores configuration only; it does not change installed package versions.

## Optional commands

```sh
make stow                    # link configs only
make check                   # validate links, scripts, and refresh/restore
make prune-brew              # preview Homebrew removals
make prune-brew action=apply # save a Brewfile snapshot, then remove unlisted items
```

`make prune-brew` is only for a machine that should match the shared
`brew/Brewfile`. Put work-only packages in
`~/.config/dotfiles/Brewfile.local` first. `make install` does not prune.

## Local settings

Rosé Pine is shared across the configs. The shell uses Powerlevel10k;
Neovim uses lazy.nvim; `mat` opens Glow with the bundled theme. Keep machine
or work settings in `~/.zshrc.local`, `~/.tmux.conf.local`,
`~/.config/nvim-local.lua`, and local Git configuration. Do not put identities,
tokens, or other credentials in this directory.

Use `DRY_RUN=1 make <target>` to preview any supported target. The VPS
repository calls these same entry points through its `make *-dotfiles`
wrappers.
