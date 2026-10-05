# Dotfiles

Shell, editor, and CLI setup for macOS and Ubuntu. Stow links the configs;
Homebrew or apt installs tools. Linux binaries, Node, pnpm, and editor
dependencies have pinned versions.

## Install

The reviewed changes are on `develop` while being tested.

```sh
git clone --branch develop https://github.com/jonathanbecerra/dotfiles.git
cd dotfiles
make install
```

Run as your normal user. Installation asks for sudo when needed, checks
time synchronization on Linux, and reloads Zsh when finished. VPS guided
setup calls the same installer for its selected admin.

Package and editor installation show short progress lines. Failed steps print
their output; sudo prompts stay visible. Use `DOTFILES_VERBOSE=1 make install`
to see the full output while it runs.

If tools are already installed, use `make stow` to link configs only.

### Existing configs

Stow will not overwrite a conflicting file. Preview the reset, back up the
listed paths, then install:

```sh
make refresh
make refresh action=apply
make install
```

Backups go under `~/.local/state/dotfiles/backups/`. Restore with:

```sh
make restore backup=/path/printed/by/refresh
```

Refresh handles managed configs and listed legacy shell/editor paths.
It leaves SSH keys, history, GPG, existing Node versions, unrelated projects,
and local overrides alone. Local overrides include `.zshrc.local`,
`.tmux.conf.local`, and `~/.config/nvim-local.lua`.

### Updates

For a standalone clone:

```sh
git pull --ff-only
make install
```

For config-only changes, `make stow` and `make reload-zsh` are enough.
When installed as a VPS submodule, update from the VPS root with
`git submodule update --init --recursive`; VPS pins the dotfiles version.

## Commands

```sh
define                 # list aliases
define dpt             # print this alias/function/command definition
make check             # local syntax, configuration, and regression checks
make check-editor      # download pinned editor/plugins and test them in a temporary directory
make prune-brew        # preview Homebrew cleanup
make prune-brew action=apply
```

Put extra Homebrew packages in `~/.config/dotfiles/Brewfile.local` before
pruning. Keep machine-specific Git settings in local Git config. Do not
commit credentials or tokens.

### Docker

Only `dc*` commands depend on your current Compose directory. The other
commands address the selected Docker daemon.

| Command | Purpose |
| --- | --- |
| `dps`, `dpsa` | List running or all containers |
| `dcup`, `dcdown`, `dcrs`, `dcps` | Start, stop, restart, or inspect the current Compose project |
| `dlogs <container>` | Follow the last 100 log lines |
| `dpt [container]` | Show published ports |
| `dst` | Show a resource snapshot |
| `dstall` | Stop all running containers |
| `dts <container>` | Confirm removal of one container, its unused image and attached volumes; keep networks |
| `dtd` | Confirm global teardown, including unused named volumes |

`dtd` affects every project on the selected daemon. It stops containers,
then prunes containers, images, build cache, unused networks, and named and
anonymous volumes. Docker's built-in networks and bind-mounted host files
remain. Deleted volume contents cannot be restored by dotfiles backups.

### Search and copy

`rg` is ripgrep's executable name. Neither `grep` nor `rgrep` is aliased.

```sh
grep 'TODO' README.md          # search this file
printf 'TODO\n' | grep TODO    # filter stdin
rg 'TODO'                     # search files under the current directory
rg -n 'TODO' src               # search src/ recursively, with line numbers
rg --no-ignore 'TODO' .        # also search ignored files
```

Both can search a named file or stdin. The difference is their defaults:
without a file or pipe, `grep` waits for stdin and `rg` searches the current
directory. Ripgrep respects ignore files and normally skips hidden files.
These dotfiles deliberately enable hidden-file searching while excluding
`.git/`. Use `rg --no-config` for stock defaults. Flags and regex options
also differ, so scripts should keep the command they were written for.

`fzfc` uses fzf to choose what to copy:

```sh
fzfc /etc/caddy/Caddyfile     # search the file's contents and copy a selected line
cat /etc/caddy/Caddyfile | fzfc
fzfc                        # search filenames, then copy the selected file's contents
```

Over SSH it uses OSC 52 when no local clipboard program is available. Your
terminal must permit it.

## Layout

Stow packages such as `zsh/`, `nvim/`, and `git/` mirror their paths under
your home directory. `scripts/` installs and checks them, `deps/` pins
versions, and `apt/` and `brew/` declare platform dependencies.
`config/refresh-paths.txt` lists legacy paths in addition to the managed
Stow paths.

`DRY_RUN=1 make <target>` previews supported commands. The repository works
on its own or as the VPS project's `dotfiles/` submodule.
