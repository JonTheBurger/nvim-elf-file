#==============================================================================#
# Project
#==============================================================================#
.DEFAULT_GOAL := help
.ONESHELL:
.PHONY: ${MAKECMDGOALS}
RED := \033[1;31m
BLU := \033[36m
RST := \033[0m
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
LUAROCKS := luarocks --lua-version 5.1 --tree ${MAKEFILE_DIR}.luarocks

## IN_NIX: [0] Set to 1 to run a command in the nix shell (make clean between nix and host shells)
ifeq ($(IN_NIX),1)
	.SHELLFLAGS := develop --command sh -ce
	SHELL := nix
endif

#==============================================================================#
# Environment
#==============================================================================#
export PATH := ${MAKEFILE_LIST}.luarocks/bin:${PATH}
export VIMRUNTIME = $(shell nvim --clean --headless --cmd 'lua io.write(os.getenv("VIMRUNTIME"))' --cmd 'quit')

#==============================================================================#
# Goals
#==============================================================================#
help: ## Shows this message
	@printf '${RED}Usage:\n  ${RST}${BLU}make [<VARIABLE>=<value>] <goal>\n${RST}'
	@printf '${RED}Targets:\n${RST}'
	@cat ${MAKEFILE_LIST} | awk -F'(:|##|])\\s*' '/[^:]*:[^:]+##\s.*$$/ {printf "  ${BLU}%-18s${RST} %s\n", $$1, $$3}'
	@printf '${RED}Variables:\n${RST}'
	@cat ${MAKEFILE_LIST} | awk -F'(:|##|])\\s*' '/##\s*[A-Z_]+:.*$$/ {printf "  ${BLU}%-18s ${RED}%s]${RST} %s\n", $$2, $$3, $$4}'

clean: ## Deletes artifacts
	rm -rf .luarocks

distclean: ## Resets the repo back to its state at checkout
	git clean -xdff

shell: ## Enter a shell containing dev dependencies
	nix develop

setup: ## Once-per-clone setup
	${LUAROCKS} install busted 2.2.0-1
	${LUAROCKS} install llscheck 0.7.0-1
	${LUAROCKS} install luacheck 1.2.0-1
	${LUAROCKS} install nlua 0.3.2-1
	${LUAROCKS} install plenary.nvim scm-1

check: format lint test ## Runs quality assurance steps

format: ## Reformats code
	@printf '${BLU}=== formatting ===${RST}\n'
	stylua lua plugin spec

lint: ## Runs static analysis tools
	@printf '${BLU}=== stylua ===${RST}\n'
	stylua lua plugin spec --color always --check
	printf '${BLU}=== luacheck ===${RST}\n'
	luacheck lua plugin spec
	printf '${BLU}=== llscheck ===${RST}\n'
	VIMRUNTIME=${VIMRUNTIME} llscheck .

test: ## Runs tests
	@printf '${BLU}=== testing ===${RST}\n'
	$(shell ${LUAROCKS} path) && busted

docs: ## Build the documentation
	@printf '${BLU}=== documentation ===${RST}\n'
	panvimdoc --project-name nvim-elf-file --input-file README.md
	nvim -es -c 'helptags doc' -c 'q'
