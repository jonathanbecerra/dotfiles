.DEFAULT_GOAL := help
export DRY_RUN DOTFILES_TARGET
.PHONY: help install reload-zsh stow refresh restore prune-brew check

help:
	@printf '%s\n' \
	  'make install                    Install tools and link configs' \
	  'make reload-zsh                 Start a fresh login shell' \
	  'make refresh                    Preview an existing-machine reset' \
	  'make refresh action=apply       Back up old config, then reset it' \
	  'make restore backup=/path       Undo a refresh from its backup' \
	  'make stow                       Link configs only' \
	  'make prune-brew                 Preview Homebrew removals' \
	  'make prune-brew action=apply    Apply Homebrew cleanup' \
	  'make check                      Validate the dotfiles checkout' \
	  'DRY_RUN=1 make <target>          Preview supported commands'

install:
	@bash scripts/install.sh --reload-shell

reload-zsh:
	@printf '\033[<u\033[=0;1u'
	@exec env -u ZDOTDIR zsh -l

stow:
	@bash scripts/stow.sh

refresh:
	@bash scripts/refresh.sh $(or $(action),plan) $(if $(paths),--extra-paths "$(paths)")

restore:
	@bash scripts/refresh.sh restore "$(backup)"

prune-brew:
	@bash scripts/manage-brew.sh $(or $(action),plan)

check:
	@bash scripts/check.sh
