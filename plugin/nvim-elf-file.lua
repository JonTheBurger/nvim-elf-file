if not vim.g.loaded_nvim_elf_file then
  local elf = require("nvim-elf-file")
  local when_elf = function(path)
    if elf.is_elf_file(path) then
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
        elf.toggle_bin()
      elseif toggle == "elf" then
        elf.toggle_elf()
      else
        if elf.is_elf_file() then
          elf.toggle_elf()
        else
          elf.toggle_bin()
        end
      end
    elseif sub == "dump" then
      elf.dump()
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

  vim.keymap.set(
    "n",
    "<Plug>(nvim-elf-file-toggle-elf)",
    require("nvim-elf-file").toggle_elf,
    { noremap = true, desc = "Toggle readelf display" }
  )
  vim.keymap.set(
    "n",
    "<Plug>(nvim-elf-file-toggle-bin)",
    require("nvim-elf-file").toggle_bin,
    { noremap = true, desc = "Toggle xxd binary display" }
  )
  vim.keymap.set(
    "n",
    "<Plug>(nvim-elf-file-dump)",
    require("nvim-elf-file").dump,
    { noremap = true, desc = "Dump section/symbol/file under cursor" }
  )
  -- vim.keymap.set(
  --   "n",
  --   "<Plug>(nvim-elf-file-hover)",
  --   require("nvim-elf-file").hover,
  --   { noremap = true, desc = "Show a hover with additional info" }
  -- )
  -- vim.keymap.set(
  --   "n",
  --   "<Plug>(nvim-elf-file-search)",
  --   require("nvim-elf-file").search,
  --   { noremap = true, desc = "Search for raw bytes in a binary file" }
  -- )
end

vim.g.loaded_nvim_elf_file = true
