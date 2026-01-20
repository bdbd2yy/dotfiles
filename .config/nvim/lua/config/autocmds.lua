-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("filetype_indent"),
  pattern = { "c", "cpp", "rust", "python" },
  callback = function()
    vim.opt.expandtab = true
    vim.opt.tabstop = 4
    vim.opt.shiftwidth = 4
    vim.opt.formatoptions:remove({ "o" }) -- 防止使用 o 切换到下一行的时候自动加上注释符号(在上一行是注释的情况下)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("filetype_spell"),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.spell = false
  end,
})

-- 在文件类型为 'markdown' 时执行命令
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("file_diagnostics"),
  pattern = "markdown",
  callback = function()
    -- 关闭所有诊断
    vim.diagnostic.enable(false)
  end,
})
