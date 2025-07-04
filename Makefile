#==============================================================================#
# Project
#==============================================================================#
.DEFAULT_GOAL := help
.PHONY: ${MAKECMDGOALS}
RED := \033[1;31m
BLU := \033[36m
RST := \033[0m
export PATH := ${PWD}/.luarocks/bin:${PATH}

#==============================================================================#
# Goals
#==============================================================================#
help: ## Shows this message
	@printf '${RED}Usage:\n  ${RST}${BLU}make [<VARIABLE>=<value>] <goal>\n${RST}'
	@printf '${RED}Targets:\n${RST}'
	@cat ${MAKEFILE_LIST} | awk -F'(:|##|])\\s*' '/[^:]*:[^:]+##\s.*$$/ {printf "  ${BLU}%-18s${RST} %s\n", $$1, $$3}'
	@printf '${RED}Variables:\n${RST}'
	@cat ${MAKEFILE_LIST} | awk -F'(:|##|])\\s*' '/##\s*[A-Z_]+:.*$$/ {printf "  ${BLU}%-18s ${RED}%s]${RST} %s\n", $$2, $$3, $$4}'

clean: ## Deletes the build dir
	rm -rf .cache

distclean: ## Resets the repo back to its state at checkout
	git clean -xdff

shell: ## Enter a development shell
	nix develop

setup: ## Once-per-clone setup
	luarocks --tree .luarocks install llscheck 0.7.0-1
	luarocks --tree .luarocks install luacheck 1.2.0-1
	luarocks --tree .luarocks install luacov 0.16.0-1
	# git clone https://github.com/nvim-lua/plenary.nvim .luarocks/plenary.nvim
	# git -C .luarocks/plenary.nvim checkout

docs: ## Build the documentation
	@printf '${BLU}=== documentation ===${RST}\n'
	@panvimdoc --project-name nvim-elf-file --input-file README.md
	@nvim -es -c 'helptags doc' -c 'q'

check: format lint test cov ## Runs quality assurance steps

format: ## Reformats code
	@printf '${BLU}=== formatting ===${RST}\n'
	@stylua lua plugin tests

lint: ## Runs static analysis tools
	@printf '${BLU}=== stylua ===${RST}\n'
	@stylua lua plugin tests --color always --check
	@printf '${BLU}=== luacheck ===${RST}\n'
	@luacheck lua plugin tests
	@printf '${BLU}=== llscheck ===${RST}\n'
	@VIMRUNTIME="`nvim --clean --headless --cmd 'lua io.write(os.getenv("VIMRUNTIME"))' --cmd 'quit'`" llscheck .

test: ## Runs tests
	@printf '${BLU}=== testing ===${RST}\n'
	@nvim \
		--headless \
		--noplugin \
		-u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests { minimal_init = 'tests/minimal_init.lua' }"

cov: ## Generates test coverage
	@printf '${BLU}=== coverage ===${RST}\n'
	@luacov
