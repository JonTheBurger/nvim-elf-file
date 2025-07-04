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
        if api.is_elf_file() then
          api.toggle_elf()
        else
          api.toggle_bin()
        end
      end
    elseif sub == "dump" then
      api.dump()
      -- elseif sub == "hover" then
      --   elf.hover()
      -- elseif sub == "search" then
      --   elf.search()
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
      end
      return { "toggle", "dump" } --, "hover", "search" }
    end,
  })

  vim.keymap.set("n", "<Plug>(nvim-elf-file-toggle-elf)", function()
    require("nvim-elf-file").toggle_elf()
  end, { noremap = true, desc = api.COMMANDS["toggle-elf"] })
  vim.keymap.set("n", "<Plug>(nvim-elf-file-toggle-bin)", function()
    require("nvim-elf-file").toggle_bin()
  end, { noremap = true, desc = api.COMMANDS["toggle-bin"] })
  vim.keymap.set("n", "<Plug>(nvim-elf-file-dump)", function()
    require("nvim-elf-file").dump()
  end, { noremap = true, desc = api.COMMANDS["dump"] })
  -- vim.keymap.set(
  --   "n",
  --   "<Plug>(nvim-elf-file-hover)",
  --   function() require("nvim-elf-file").hover() end,
  --   { noremap = true, desc = elf.COMMANDS["hover"] }
  -- )
  -- vim.keymap.set(
  --   "n",
  --   "<Plug>(nvim-elf-file-search)",
  --   function() require("nvim-elf-file").search() end,
  --   { noremap = true, desc = elf.COMMANDS["search"] }
  -- )
end

vim.g.loaded_nvim_elf_file = true
