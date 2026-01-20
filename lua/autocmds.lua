--- AUTOCMDS ---

local function create_autocmd(event, rhs, desc, opts)
  if not opts and type(desc) == "table" then
    opts, desc = desc, nil
  end
  opts = vim.deepcopy(opts or {})
  opts.desc = desc and tostring(desc) or opts.desc
  opts.command, opts.callback = nil, nil
  if type(rhs) == "string" then
    opts.command = rhs
  else
    opts.callback = rhs
  end
  return vim.api.nvim_create_autocmd(event, opts)
end

local augroup = vim.api.nvim_create_augroup("vimrc_autocmds", { clear = true })
create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, function()
  if vim.o.buftype == "nofile" then return end
  return vim.cmd.checktime()
end, { group = augroup })
create_autocmd("TextYankPost", function() return vim.hl.on_yank() end, { group = augroup })
create_autocmd({ "VimResized" }, function()
  local current_tab = vim.fn.tabpagenr()
  vim.cmd("tabdo wincmd =")
  vim.cmd("tabnext " .. current_tab)
end, { group = augroup })
create_autocmd("FileType", "setlocal formatoptions-=c formatoptions-=r formatoptions-=o", {
  desc = "Disable auto-comments",
  group = augroup,
})

