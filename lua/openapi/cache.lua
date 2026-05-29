local M = {}

-- entry: { tick = changedtick, model = openapi.Model }
local store = {}

---Get cached value for a buffer if its changedtick matches.
---@param bufnr integer
---@return openapi.Model?
function M.get(bufnr)
  local entry = store[bufnr]
  if entry and entry.tick == vim.b[bufnr].changedtick then
    return entry.model
  end
  return nil
end

---Store a model for a buffer keyed by its current changedtick.
---@param bufnr integer
---@param model openapi.Model
function M.set(bufnr, model)
  store[bufnr] = { tick = vim.b[bufnr].changedtick, model = model }
end

---@param bufnr integer
function M.invalidate(bufnr)
  store[bufnr] = nil
end

return M
