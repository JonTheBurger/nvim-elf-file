if not vim.g.loaded_nvim_elf_file then
  local api = require("nvim-elf-file")
  local when_elf = function(path)
    if api.is_elf_file(path) then
      return "elf"
    end
  end

  vim.filetype.add({
    extension = {
      axf = "elf",
      bin = "bin",
      elf = "elf",
      o = "elf",
      obj = when_elf,
      out = when_elf,
      so = "elf",
    },
    pattern = {
      [".*/bin/.*"] = when_elf,
      ["[^.]+"] = when_elf,
    },
  })

  vim.api.nvim_create_user_command("ElfFile", function(opts)
    local sub = opts.fargs[1]
    if sub == "toggle" then
      local toggle = opts.fargs[2]
      if toggle == "bin" then
        api.toggle_bin()
      elseif toggle == "elf" then
        api.toggle_elf()
      else
        api.toggle()
      end
    elseif sub == "dump" then
      api.dump()
    elseif sub == "jump" then
      api.jump()
    elseif sub == "hover" then
      api.hover()
    elseif sub == "search" then
      local search = opts.fargs[2]
      if search == "bin" then
        api.search_binary()
      elseif search == "text" then
        api.search_text()
      end
    elseif sub == "help" then
      api.help()
    elseif sub == "refresh" then
      api.refresh()
    end
  end, {
    nargs = "+",
    ---Completion called when a space occurs between args
    ---@param _ nil Ignored arg_lead
    ---@param line string EX command line
    ---@param cursor integer Cursor position
    ---@return string[] auto-complete Suggestion list
    complete = function(_, line, cursor)
      line = line:sub(1, cursor)
      if line:find("^ElfFile%s+toggle") then
        return { "bin", "elf" }
      elseif line:find("^ElfFile%s+search") then
        return { "bin", "text" }
      end
      return { "toggle", "dump", "jump", "hover", "search", "help", "refresh" }
    end,
  })

  vim.keymap.set("n", "<Plug>(nvim-elf-file-help)", function()
    require("nvim-elf-file").help()
  end, { noremap = true, desc = api.COMMANDS["help"] })
  vim.keymap.set("n", "<Plug>(nvim-elf-file-toggle)", function()
    require("nvim-elf-file").toggle()
  end, { noremap = true, desc = api.COMMANDS["toggle"] })
  vim.keymap.set("n", "<Plug>(nvim-elf-file-toggle-elf)", function()
    require("nvim-elf-file").toggle_elf()
  end, { noremap = true, desc = api.COMMANDS["toggle-elf"] })
  vim.keymap.set("n", "<Plug>(nvim-elf-file-toggle-bin)", function()
    require("nvim-elf-file").toggle_bin()
  end, { noremap = true, desc = api.COMMANDS["toggle-bin"] })
  vim.keymap.set("n", "<Plug>(nvim-elf-file-dump)", function()
    require("nvim-elf-file").dump()
  end, { noremap = true, desc = api.COMMANDS["dump"] })
  vim.keymap.set("n", "<Plug>(nvim-elf-file-jump)", function()
    require("nvim-elf-file").jump()
  end, { noremap = true, desc = api.COMMANDS["jump"] })
  vim.keymap.set("n", "<Plug>(nvim-elf-file-hover)", function()
    require("nvim-elf-file").hover()
  end, { noremap = true, desc = api.COMMANDS["hover"] })
  vim.keymap.set("n", "<Plug>(nvim-elf-file-search-text)", function()
    require("nvim-elf-file").search_text()
  end, { noremap = true, desc = api.COMMANDS["search-text"] })
  vim.keymap.set("n", "<Plug>(nvim-elf-file-search-bin)", function()
    require("nvim-elf-file").search_binary()
  end, { noremap = true, desc = api.COMMANDS["search-bin"] })
  vim.keymap.set("n", "<Plug>(nvim-elf-file-refresh)", function()
    require("nvim-elf-file").refresh()
  end, { noremap = true, desc = api.COMMANDS["refresh"] })
end

vim.g.loaded_nvim_elf_file = true
