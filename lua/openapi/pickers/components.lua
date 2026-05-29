local parser = require("openapi.parser")
local util = require("openapi.util")

local M = {}

local KIND_W = 14

---Open the components picker.
---@param bufnr? integer
---@param kind? string  optional filter by component kind (e.g. "schemas")
function M.open(bufnr, kind)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local model, err = parser.parse(bufnr)
  if not model then
    vim.notify("openapi: " .. (err or "parse failed"), vim.log.levels.WARN)
    return
  end

  ---@type snacks.picker.finder.Item[]
  local items = {}
  for _, c in ipairs(model.components) do
    if not kind or c.kind == kind then
      items[#items + 1] = {
        text = c.kind .. " " .. c.name,
        kind = c.kind,
        name = c.name,
        pointer = c.pointer,
        buf = bufnr,
        pos = { c.pos.row, c.pos.col },
      }
    end
  end

  if #items == 0 then
    vim.notify("openapi: no components" .. (kind and (" of kind " .. kind) or "") .. " found", vim.log.levels.INFO)
    return
  end

  local title = "OpenAPI Components" .. (kind and (" (" .. kind .. ")") or "")

  if not util.has_snacks_picker() then
    return M.fallback_select(items, title)
  end

  Snacks.picker.pick({
    source = "openapi_components",
    title = title,
    items = items,
    format = function(item)
      ---@type snacks.picker.Highlight[]
      local ret = {}
      ret[#ret + 1] = { string.format("%-" .. KIND_W .. "s", item.kind), "Type" }
      ret[#ret + 1] = { " " }
      ret[#ret + 1] = { item.name, "Identifier" }
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

---@param items table[]
---@param title string
function M.fallback_select(items, title)
  vim.ui.select(items, {
    prompt = title,
    format_item = function(item)
      return string.format("%-14s %s", item.kind, item.name)
    end,
  }, function(item)
    if item then
      util.jump({ row = item.pos[1], col = item.pos[2] }, item.buf)
    end
  end)
end

return M
