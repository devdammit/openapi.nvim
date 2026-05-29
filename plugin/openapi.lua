-- Auto-setup with defaults if the user hasn't called setup() yet.
-- Plugin managers using `opts` will call setup() themselves; this guard
-- makes the plugin usable even when loaded without explicit configuration.
if vim.g.loaded_openapi_nvim then
  return
end
vim.g.loaded_openapi_nvim = true

-- Defer to allow user setup() to run first during startup.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "yaml",
  once = true,
  callback = function()
    if not vim.g.openapi_nvim_setup_done then
      vim.g.openapi_nvim_setup_done = true
      require("openapi").setup()
    end
  end,
})
