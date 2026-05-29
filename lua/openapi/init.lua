local config = require("openapi.config")

local M = {}

local augroup = vim.api.nvim_create_augroup("openapi_nvim", { clear = true })

---@param opts? openapi.Config
function M.setup(opts)
  vim.g.openapi_nvim_setup_done = true
  config.setup(opts)

  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "yaml",
    callback = function(args)
      local bufnr = args.buf
      if require("openapi.detect").is_openapi_buf(bufnr) then
        require("openapi.attach").on_attach(bufnr)
        require("openapi.highlight").attach(bufnr)
      end
    end,
  })

  -- LSP (e.g. yamlls via LazyVim) sets gd/gr buffer-local keymaps reactively
  -- through Snacks.util.lsp.on(), which fires deferred when a matching client
  -- attaches -- after our FileType callback. Reapply our keymaps after a short
  -- delay so we reliably win that ordering race.
  -- Snacks (used by LazyVim) re-evaluates LSP keymaps on a 100ms debounce after
  -- LspAttach, so a single 50ms defer loses. Reassert after the debounce window
  -- (and once more) to reliably keep ownership of gd/gr.
  local function reapply(bufnr)
    if require("openapi.detect").is_openapi_buf(bufnr) then
      for _, delay in ipairs({ 150, 300 }) do
        vim.defer_fn(function()
          if vim.api.nvim_buf_is_valid(bufnr) then
            require("openapi.attach").set_keymaps(bufnr)
          end
        end, delay)
      end
    end
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    group = augroup,
    callback = function(args)
      reapply(args.buf)
    end,
  })

  -- Also reassert ownership when re-entering the buffer.
  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    callback = function(args)
      if vim.bo[args.buf].filetype == "yaml" then
        reapply(args.buf)
      end
    end,
  })

  -- Handle buffers already open at setup time.
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and require("openapi.detect").is_openapi_buf(bufnr) then
      require("openapi.attach").on_attach(bufnr)
      require("openapi.highlight").attach(bufnr)
    end
  end
end

return M
