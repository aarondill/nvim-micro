local function clone(name, repo, cb)
  local path = vim.fn.stdpath("data") .. "/site/pack/" .. name .. "/start/" .. name
  local is_installed = vim.fn.empty(vim.fn.glob(path)) == 0
  local on_done = vim.schedule_wrap(function()
    vim.cmd.packadd(name)
    if cb then
      cb()
    end
  end)
  if is_installed then
    return on_done()
  end
  vim.fn.mkdir(path, "p")
  vim.system({ "git", "clone", "https://github.com/" .. repo, path }, nil, on_done)
end

clone("nvim-treesitter", "nvim-treesitter/nvim-treesitter", function()
  vim.cmd("TSUpdate")
end)
clone("tokyonight", "folke/tokyonight.nvim", function()
  require("tokyonight").setup({
    transparent = true, -- Enable this to disable setting the background color
    dim_inactive = true, -- dims inactive windows
    style = "night", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
    styles = {
      sidebars = "transparent",
      floats = "transparent",
    },
  })
  vim.cmd.colorscheme("tokyonight-night")
end)

clone("mini.bufremove", "nvim-mini/mini.bufremove", function()
  vim.keymap.set("n", "<leader>bd", function()
    local bd = require("mini.bufremove").delete
    if not vim.bo.modified then
      return bd(0)
    end

    local msg = ("Save changes to %q?"):format(vim.fn.bufname())
    local choice = vim.fn.confirm(msg, "&Yes\n&No\n&Cancel")
    if choice == 3 or choice == 0 then
      return
    end -- Cancel
    if choice == 1 then
      vim.cmd.write()
    end -- Yes
    local force = choice == 2
    return bd(0, force)
  end, { desc = "Delete Buffer" })
  vim.keymap.set("n", "<leader>bD", function()
    require("mini.bufremove").delete(0, true)
  end, { desc = "Delete Buffer (Force)" })
end)

clone("bufferline", "akinsho/bufferline.nvim", function()
  local opts = { ---@type bufferline.UserConfig
    options = {
      close_command = function(n)
        require("mini.bufremove").delete(n, false)
      end,
      right_mouse_command = function(n)
        require("mini.bufremove").delete(n, false)
      end,
      diagnostics = "nvim_lsp",
      always_show_bufferline = false,
      diagnostics_indicator = function(_, _, diag)
        local icons = require("config.icons").diagnostics
        local ret = {}
        if diag.error then
          ret[#ret + 1] = icons.error .. diag.error
        end
        if diag.warning then
          ret[#ret + 1] = icons.warn .. diag.warning
        end
        return table.concat(ret, " ")
      end,
      offsets = {
        {
          filetype = "neo-tree",
          text = "Neo-tree",
          highlight = "Directory",
          text_align = "left",
        },
      },
    },
  }
  require("bufferline").setup(opts)
  -- Fix bufferline when restoring a session
  vim.api.nvim_create_autocmd("BufAdd", {
    callback = vim.schedule_wrap(function()
      return pcall(nvim_bufferline)
    end),
  })
end)

require("maps")
require("autocmds")
require("options")
