-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local unmap = vim.keymap.del

map({"i", "v"}, "jk", "<Esc>", { noremap = true, silent = true })
map({"v"}, "q", "<Esc>", { noremap = true, silent = true })
map({"t"}, "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
map({"t"}, "jk", "<C-\\><C-n>", { noremap = true, silent = true })
unmap("n", "<leader><space>", { desc = "Find Files (root dir)" })

-- toggle color between 雷姆蓝 and 拉姆粉
local color_switch = 0
local function toggle_color()
  if color_switch == 1 then
    color_switch = 0
    vim.cmd("highlight Cursor gui=NONE guifg=bg guibg=#ffb6c1")
  else
    color_switch = 1
    vim.cmd("highlight Cursor gui=NONE guifg=bg guibg=#91bef0")
  end
end
map("n", "<leader><leader>t", function()
  toggle_color()
end, { desc = "Toggle gui cursor color" })

-- 
if vim.g.neovide then
  vim.keymap.set({ "n", "v" }, "<c-=>", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>")
  vim.keymap.set({ "n", "v" }, "<c-->", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>")
  vim.keymap.set({ "n", "v" }, "<c-0>", ":lua vim.g.neovide_scale_factor = 1<CR>")
end

-- toggleterm
map("n", "<leader>th", "<cmd>ToggleTerm size=15 direction=horizontal<cr>", { desc = "ToggleTerm horizontal split" })
map("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "ToggleTerm float" })
-- map("n", "<leader>tt", "<cmd>ToggleTerm direction=tab<cr>", { desc = "ToggleTerm float" })
map("n", "<leader>tv", "<cmd>ToggleTerm size=80 direction=vertical<cr>", { desc = "ToggleTerm vertical split" })
