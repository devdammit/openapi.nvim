local config = require("openapi.config")

local M = {}

-- Cache detection result per buffer (keyed by changedtick of first scan).
local cache = {}

---Return true if the buffer looks like an OpenAPI/Swagger spec.
---Heuristic: a YAML buffer whose leading lines contain a top-level
---`openapi:` or `swagger:` key.
---@param bufnr integer
---@return boolean
function M.is_openapi_buf(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  if vim.bo[bufnr].filetype ~= "yaml" then
    return false
  end

  local tick = vim.b[bufnr].changedtick
  local cached = cache[bufnr]
  if cached and cached.tick == tick then
    return cached.result
  end

  local n = config.options.detect_lines or 50
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, n, false)
  local result = false
  for _, line in ipairs(lines) do
    if line:match("^%s*openapi%s*:") or line:match("^%s*swagger%s*:") then
      result = true
      break
    end
  end

  cache[bufnr] = { tick = tick, result = result }
  return result
end

return M
