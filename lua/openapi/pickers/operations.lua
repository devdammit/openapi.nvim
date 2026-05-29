local parser = require("openapi.parser")
local util = require("openapi.util")

local M = {}

-- Fixed-width method column for alignment.
local METHOD_W = 7

---Open the operations picker.
---@param bufnr? integer
function M.open(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local model, err = parser.parse(bufnr)
  if not model then
    vim.notify("openapi: " .. (err or "parse failed"), vim.log.levels.WARN)
    return
  end
  if #model.operations == 0 then
    vim.notify("openapi: no operations found", vim.log.levels.INFO)
    return
  end

  ---@type snacks.picker.finder.Item[]
  local items = {}
  for _, op in ipairs(model.operations) do
    local label = op.operationId or ""
    local summary = op.summary or ""
    local text = table.concat({ op.method, op.path, label, summary }, " ")
    items[#items + 1] = {
      text = text,
      method = op.method,
      path = op.path,
      operationId = op.operationId,
      summary = summary,
      buf = bufnr,
      pos = { op.pos.row, op.pos.col },
    }
  end

  if not util.has_snacks_picker() then
    return M.fallback_select(items)
  end

  Snacks.picker.pick({
    source = "openapi_operations",
    title = "OpenAPI Operations",
    items = items,
    format = function(item)
      local method = string.format("%-" .. METHOD_W .. "s", item.method)
      ---@type snacks.picker.Highlight[]
      local ret = {}
      ret[#ret + 1] = { method, "Function" }
      ret[#ret + 1] = { " " }
      ret[#ret + 1] = { item.path, "Identifier" }
      if item.operationId and item.operationId ~= "" then
        ret[#ret + 1] = { "  " }
        ret[#ret + 1] = { item.operationId, "Comment" }
      end
      if item.summary and item.summary ~= "" then
        ret[#ret + 1] = { "  " }
        ret[#ret + 1] = { item.summary, "Comment" }
      end
      return ret
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        util.jump({ row = item.pos[1], col = item.pos[2] }, item.buf)
      end
    end,
  })
end

---Minimal fallback using vim.ui.select when Snacks isn't available.
---@param items table[]
function M.fallback_select(items)
  vim.ui.select(items, {
    prompt = "OpenAPI Operations",
    format_item = function(item)
      return string.format("%-7s %s  %s", item.method, item.path, item.operationId or "")
    end,
  }, function(item)
    if item then
      util.jump({ row = item.pos[1], col = item.pos[2] }, item.buf)
    end
  end)
end

return M
