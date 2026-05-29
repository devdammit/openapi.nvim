local cache = require("openapi.cache")
local model_builder = require("openapi.parser.model")

local M = {}

---Parse a buffer into an OpenAPI model, using the per-buffer cache when valid.
---@param bufnr? integer
---@return openapi.Model? model, string? err
function M.parse(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local cached = cache.get(bufnr)
  if cached then
    return cached, nil
  end

  local model, err = model_builder.build(bufnr)
  if not model then
    return nil, err
  end

  cache.set(bufnr, model)
  return model, nil
end

return M
