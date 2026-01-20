-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 关闭自动格式化
vim.g.autoformat = false
vim.g.neovide_cursor_vfx_mode = "pixiedust"
vim.g.neovide_floating_shadow = false
vim.g.neovide_input_ime = true
vim.g.neovide_cursor_vfx_particle_density = 100.0
-- 输入时隐藏鼠标
vim.g.neovide_hide_mouse_when_typing = true
-- vim.g.neovide_fullscreen = false
-- vim.g.neovide_maximized = true
local opt = vim.opt

vim.g.deprecation_warnings = true

-- 关闭相对行号
opt.relativenumber = false
-- 禁用拼写检查
opt.spell = false
-- md等文件中所有字符均不隐藏
opt.conceallevel = 0
-- 设置字体
opt.guifont = "Maple Mono, UbuntuMono Nerd Font,文泉驿等宽微米黑,Symbola,:h20"
-- 将空格替换为·
opt.list = true
opt.listchars = { space = "·", tab = "▸ " }
-- 开启折叠
opt.wrap = true

-- 确保在主题加载后设置光标颜色
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr:hor20-Cursor,o:hor50-Cursor"
    vim.cmd("highlight Cursor gui=NONE guifg=bg guibg=#ffb6c1")
  end,
})
