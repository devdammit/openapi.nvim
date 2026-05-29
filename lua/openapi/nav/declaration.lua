local parser = require("openapi.parser")
local context = require("openapi.nav.context")
local util = require("openapi.util")

local M = {}

---Fallback to the default LSP definition behaviour.
local function lsp_fallback()
  if next(vim.lsp.get_clients({ bufnr = 0 })) ~= nil then
    vim.lsp.buf.definition()
  else
    vim.notify("openapi: not on a $ref and no LSP available", vim.log.levels.INFO)
  end
end

---Go to the declaration referenced by the $ref under the cursor.
---Falls back to LSP definition when the cursor isn't on a $ref.
---@param bufnr? integer
function M.goto_declaration(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local ctx = context.at_cursor(bufnr)
  if ctx.kind ~= "ref" then
    return lsp_fallback()
  end

  -- External refs (multi-file) are not supported yet.
  if ctx.file then
    vim.notify("openapi: external $ref navigation not supported yet (" .. ctx.ref.value .. ")", vim.log.levels.WARN)
    return
  end

  if not ctx.pointer then
    vim.notify("openapi: empty $ref", vim.log.levels.WARN)
    return
  end

  local model, err = parser.parse(bufnr)
  if not model then
    vim.notify("openapi: " .. (err or "parse failed"), vim.log.levels.WARN)
    return
  end

  local pos = model.targets[ctx.pointer]
  if not pos then
    vim.notify("openapi: target not found for " .. ctx.pointer, vim.log.levels.WARN)
    return
  end

  util.jump(pos, bufnr)
end

return M
