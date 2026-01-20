local function clone(name, repo, cb)
  local path = vim.fn.stdpath("data") .. "/site/pack/" .. name .. "/start/" .. name
  local is_installed = vim.fn.empty(vim.fn.glob(path)) == 0
  local on_done = vim.schedule_wrap(function()
    vim.cmd.packadd(name)
    if cb then cb() end
  end)
  if is_installed then return on_done() end
  vim.fn.mkdir(path, "p")
  vim.system({ "git", "clone", "https://github.com/" .. repo, path }, nil, on_done)
end

clone("nvim-treesitter", "nvim-treesitter/nvim-treesitter", function() vim.cmd("TSUpdate") end)
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


require('maps')
require('autocmds')
require('options')
