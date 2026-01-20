local function map(mode, lhs, rhs, desc, opts)
  if type(desc) == "string" then
    opts = vim.tbl_extend("force", opts or {}, { desc = desc })
  else
    assert((desc == nil or type(desc) == "table") and opts == nil, "Desc can only be a table if opts is nil")
    opts = desc
  end
  opts = opts or {}

  assert(type(lhs) == "table" or type(lhs) == "string", "lhs must be a string or table")
  ---@type string[]
  lhs = type(lhs) == "table" and lhs or { lhs }
  for _, l in ipairs(lhs) do
    vim.keymap.set(mode, l, rhs, opts)
  end
end

local function get_vtext()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "" then return nil end
  local lines = vim.fn.getregion(vim.fn.getpos("."), vim.fn.getpos("v"), { type = vim.fn.mode() })
  return table.concat(lines, "\n")
end


--- KEYMAPS ----

local function get_cursorline_contents() ---@return string?
  local linenr = vim.api.nvim_win_get_cursor(0)[1]
  return vim.api.nvim_buf_get_lines(0, linenr - 1, linenr, false)[1]
end

---Use in an expr mapping. Returns the mapping if the current line (or selected text) is not just whitespace
---@param input string
local function line_not_empty(input) ---@return fun(): string?
  return function()
    local vtext = get_vtext() or get_cursorline_contents()
    if not vtext then return end
    if not vtext:find("^%s*$") then return input end -- not empty
  end
end
local function toggle_movement(first, second) ---@return fun()
  first = vim.api.nvim_replace_termcodes(first, true, false, true) -- Allow <C-k> escapes
  second = vim.api.nvim_replace_termcodes(second, true, false, true)
  return function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0), 1, 2)
    vim.api.nvim_feedkeys(first, "nx", false) -- run first -- note: 'x' is needed to ensure that it happens *now*
    local nrow, ncol = unpack(vim.api.nvim_win_get_cursor(0), 1, 2)
    if row ~= nrow or col ~= ncol then return end -- it moved!
    return vim.api.nvim_feedkeys(second, "n", false) -- run then
  end
end
---Use in an expr mapping. returns <cmd>%s<cr> but with count supported
local function cmd_mapping(cmd)
  return function() return ("<cmd>%d%s<cr>"):format(vim.v.count1, cmd) end
end

-- map up/down to move over screen lines instead of file lines (only matters with 'wrap')
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", "Go to left window", { remap = true })
map("n", "<C-j>", "<C-w>j", "Go to lower window", { remap = true })
map("n", "<C-k>", "<C-w>k", "Go to upper window", { remap = true })
map("n", "<C-l>", "<C-w>l", "Go to right window", { remap = true })
map("t", "<C-h>", cmd_mapping("wincmd h"), "Go to left window")
map("t", "<C-j>", cmd_mapping("wincmd j"), "Go to lower window")
map("t", "<C-k>", cmd_mapping("wincmd k"), "Go to upper window")
map("t", "<C-l>", cmd_mapping("wincmd l"), "Go to right window")
-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", "Increase window height")
map("n", "<C-Down>", "<cmd>resize -2<cr>", "Decrease window height")
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", "Decrease window width")
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", "Increase window width")
-- Move Lines
map("n", "<A-j>", "<cmd>m .+1<cr>==", "Move down")
map("n", "<A-k>", "<cmd>m .-2<cr>==", "Move up")
map("i", "<A-k>", "<cmd>m .-2<cr><c-o>==", "Move up")
map("i", "<A-j>", "<cmd>m .+1<cr><c-o>==", "Move down")
map("v", "<A-j>", ":m '>+1<cr>gv=gv", "Move down")
map("v", "<A-k>", ":m '<-2<cr>gv=gv", "Move up")
-- buffers
map("n", { "<S-h>", "[b" }, cmd_mapping("bprevious"), "Prev buffer", { expr = true })
map("n", { "<S-l>", "]b" }, cmd_mapping("bnext"), "Next buffer", { expr = true })
-- Clear search with <esc>
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", "Escape and clear hlsearch")
-- Add undo break-points
for _, k in ipairs({ ",", ".", ";" }) do
  map("i", k, k .. "<c-g>u")
end
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", "Save file")
map("n", "<leader>fn", "<cmd>enew<cr>", "New File")
map("n", "[q", vim.cmd.cprev, "Previous quickfix")
map("n", "]q", vim.cmd.cnext, "Next quickfix")
-- diagnostic
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next Diagnostic")
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Prev Diagnostic")
map("n", "gl", function() return vim.diagnostic.open_float({ focusable = true }) end, "Diagnostic")
-- toggle options

---@param silent boolean?
---@param values? {[1]:any, [2]:any}
---@return fun() toggler the function to toggle the given option
local function toggle_option(option, values, silent)
  silent, values = silent or false, values or { true, false }
  return function()
    local new_value = values[1]
    if vim.opt_local[option]:get() == values[1] then new_value = values[2] end
    vim.opt_local[option] = new_value
    if silent then return end -- Don't notify!
    local msg = (new_value == true and "Enabled %s") or (new_value == false and "Disabled %s") or "Set %s to %s"
    vim.notify(msg:format(option, new_value), vim.log.levels.INFO)
  end
end

map("n", "<leader>us", toggle_option("spell"), "Toggle Spelling")
map("n", "<leader>uw", toggle_option("wrap"), "Toggle Word Wrap")
map("n", "<leader>uL", toggle_option("relativenumber"), "Toggle Relative Line Numbers")
map("n", "<leader>um", toggle_option("modifiable"), "Toggle Modifiable")
local conceallevel = vim.o.conceallevel > 0 and vim.o.conceallevel or 3
map("n", "<leader>uc", toggle_option("conceallevel", { 0, conceallevel }), "Toggle Conceal")
map("n", "<leader>uT", function()
  local f = vim.b.ts_highlight and vim.treesitter.stop or vim.treesitter.start
  return f()
end, "Toggle Treesitter Highlight")
-- windows
map("n", "<leader>ww", "<C-W>p", "Other window", { remap = true })
map("n", "<leader>wd", "<C-W>c", "Delete window", { remap = true })
map("n", { "<leader>-", "<leader>w-" }, "<C-W>s", "Split window below", { remap = true })
map("n", { "<leader>|", "<leader>w|" }, "<C-W>v", "Split window right", { remap = true })

-- Change U to redo for symetry with u
map("n", "U", "<c-r>", "Redo")

--- Map Ctrl+Shift+A to decrement, since Ctrl+A is increment (and Ctrl+X is remapped later)
map({ "n", "x" }, "<c-s-a>", "<c-x>", "Decrement")

-- Map Y to act like D and C, i.e. to yank until EOL, rather than act as yy,
-- which is the default
map("n", "Y", "y$", "Yank until EOL")

-- Quick save and quit
map("n", "<leader>qq", "<cmd>qa<cr>", "Quit all")
map("n", "<leader>wq", "ZZ", "Save and exit")

-- Quick quit
map("n", "<leader>q!", "ZQ", "Exit without saving")
-- Quit without shift
map("n", "<leader>q1", "ZQ", "Exit without saving")

-- Terminal allow escape to exit insert
map("t", "<Esc>", "<C-\\><C-n>", "Exit insert")
--- Fix broken shift+space and shift+enter in terminal
map("t", "<S-Space>", "<Space>")
map("t", "<S-CR>", "<CR>")

-- Map 0 to go between 0 and ^
map({ "n", "x" }, "0", toggle_movement("^", "0"), "Go to start of line", { silent = true })
map({ "n", "x" }, "^", toggle_movement("0", "^"), "Go to start of line", { silent = true })
-- Map gg to go between gg and G
map({ "n", "x" }, "gg", toggle_movement("gg", "G"), "Go to start/end of file", { silent = true })
-- Map G to go between G and gg
map({ "n", "x" }, "G", toggle_movement("G", "gg"), "Go to start/end of file", { silent = true })
map("", "<home>", "^", { desc = "Move to first non-blank char", silent = true })
map("i", "<home>", "<C-o>^", { desc = "Move to first non-blank char", silent = true })

-- Remap f9 to fold control
map("i", "<F9>", "<C-O>za", "Toggle Fold")
map("n", "<F9>", "za", "Toggle Fold")
map("o", "<F9>", "<C-C>za", "Toggle Fold")
map("x", "<F9>", "zf", "Create Fold")

map("n", "<leader>ds", "<cmd>DiffSaved<cr>", "Show the [d]iff with last [s]ave")

map("v", "<leader>rr", function()
  local t = get_vtext()
  assert(t, "No visual selection")
  return [[:<C-u>%s/\V]] .. vim.fn.escape(t, "/\\") .. "/"
end, { desc = "open :%s// with selection", expr = true })
map("n", "<leader>rr", function()
  local t = vim.fn.expand("<cword>")
  assert(t, "No word under cursor")
  return [[:<C-u>%s/\V]] .. vim.fn.escape(t, "/\\") .. "/"
end, { desc = "open :%s// with cword", expr = true })

-- Paste system clipboard with Ctrl + v
local function paste()
  ---@diagnostic disable-next-line: redundant-parameter # this works, but the types are wrong
  local clip = vim.fn.getreg("+", 1, true)
  assert(type(clip) == "table", "getreg returned a string!")
  return vim.paste(clip, -1)
end
map({ "c", "i", "n", "x" }, "<C-v>", paste, "Paste from system clipboard")
map({ "n", "x" }, "<leader>p", paste, "Paste from system clipboard") -- only in normal/select

-- Cut to system clipboard with Ctrl + x
map("x", "<C-x>", line_not_empty('"+d'), "Cut to system clipboard", { expr = true })
map("n", "<C-x>", line_not_empty('"+dd'), "Cut to system clipboard", { expr = true })
map("i", "<C-x>", line_not_empty('<ESC>"+ddi'), "Cut to system clipboard", { expr = true })

-- Copy to system clipboard with Ctr + c
map("x", "<C-c>", line_not_empty('"+y'), "[C]opy to system clipboard", { expr = true })
map("n", "<C-c>", line_not_empty('"+yy'), "[C]opy to system clipboard", { expr = true })
map("i", "<C-c>", line_not_empty('<ESC>"+yya'), "[C]opy to system clipboard", { expr = true })

-- Cd shortcuts
map("n", "<Leader>cc", "<Cmd>cd! %:h<CR>", "[c]d to [c]urrent buffer path")
map("n", "<Leader>..", "<Cmd>cd! ..<CR>", "cd up a level [..]")

map({ "i", "n" }, "<F1>", "<NOP>", "Disable help shortcut key")

map("x", "<", "<gv", "Reselect visual block after indent")
map("x", ">", ">gv", "Reselect visual block after indent")
map({ "n", "x" }, "\\", "@:", "Backslash redoes the last command")

map("x", "<C-/>", function()
  -- If :Telescope command doesn't exist, call :grep instead
  if vim.fn.exists(":Telescope") == 2 then return "<Cmd>Telescope grep_string<Cr>" end
  return ":<C-u>grep <C-r><C-w>"
end, "Grep for the selected string", { expr = true })

map("n", "<bs>", function()
  if vim.fn.getreg("#") == "" then return "<cmd>bn<cr>" end
  return "<c-^>"
end, { silent = true, noremap = true, expr = true })

-- Allow scrolling through autocomplete with up and down arrows!
map("c", "<c-p>", "<up>")
map("c", "<c-n>", "<down>")
map("c", "<up>", "<c-p>")
map("c", "<down>", "<c-n>")

-- Use Ctrl+hjkl to move in insert mode!
map("i", "<c-h>", "<left>")
map("i", "<c-j>", "<down>")
map("i", "<c-k>", "<up>")
map("i", "<c-l>", "<right>")

map("i", "<c-a>", "<c-o>^", "Beginning of line")
map("i", "<c-e>", "<End>", "End of line")
map("c", "<c-a>", "<Home>", "Beginning of line")
map("c", "<c-e>", "<End>", "End of line")

--- Enter opens command line
map({ "n", "v" }, "<CR>", ":", "Enter command line")

map({"n"}, "<Leader>bd", ":bdelete")
