local config = require("openapi.config")

local M = {}

-- Track which buffers we've already attached to, to avoid duplicate commands.
local attached = {}

local function map(bufnr, lhs, rhs, desc)
  if not lhs then
    return
  end
  vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
end

---(Re)apply the buffer-local keymaps. Safe to call multiple times; used both on
---initial attach and after LspAttach (whose keymaps would otherwise clobber ours).
---@param bufnr integer
function M.set_keymaps(bufnr)
  local keys = config.options.keys or {}

  map(bufnr, keys.declaration, function()
    require("openapi.nav.declaration").goto_declaration(bufnr)
  end, "OpenAPI: go to declaration ($ref)")

  map(bufnr, keys.references, function()
    require("openapi.nav.reference").find_references(bufnr)
  end, "OpenAPI: find references ($ref)")

  map(bufnr, keys.operations, function()
    require("openapi.pickers.operations").open(bufnr)
  end, "OpenAPI: operations")

  map(bufnr, keys.components, function()
    require("openapi.pickers.components").open(bufnr)
  end, "OpenAPI: components")
end

---Attach buffer-local keymaps and commands to an OpenAPI buffer.
---@param bufnr integer
function M.on_attach(bufnr)
  -- Always (re)apply keymaps, even if commands are already set, so that an
  -- LspAttach happening after the initial attach can restore our mappings.
  M.set_keymaps(bufnr)

  if attached[bufnr] then
    return
  end
  attached[bufnr] = true

  -- Buffer-local commands.
  vim.api.nvim_buf_create_user_command(bufnr, "OpenapiOperations", function()
    require("openapi.pickers.operations").open(bufnr)
  end, { desc = "OpenAPI: operations picker" })

  vim.api.nvim_buf_create_user_command(bufnr, "OpenapiComponents", function(o)
    require("openapi.pickers.components").open(bufnr, o.args ~= "" and o.args or nil)
  end, {
    desc = "OpenAPI: components picker",
    nargs = "?",
    complete = function()
      return require("openapi.config").ALL_COMPONENT_KINDS
    end,
  })

  vim.api.nvim_buf_create_user_command(bufnr, "OpenapiSchemas", function()
    require("openapi.pickers.components").open(bufnr, "schemas")
  end, { desc = "OpenAPI: schemas picker" })

  vim.api.nvim_buf_create_user_command(bufnr, "OpenapiReferences", function()
    require("openapi.nav.reference").find_references(bufnr)
  end, { desc = "OpenAPI: find references" })

  -- Cleanup when the buffer is wiped.
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    buffer = bufnr,
    once = true,
    callback = function()
      attached[bufnr] = nil
    end,
  })
end

return M
