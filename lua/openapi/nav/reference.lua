local parser = require("openapi.parser")
local context = require("openapi.nav.context")
local util = require("openapi.util")

local M = {}

local function lsp_fallback()
  if next(vim.lsp.get_clients({ bufnr = 0 })) ~= nil then
    vim.lsp.buf.references()
  else
    vim.notify("openapi: no references and no LSP available", vim.log.levels.INFO)
  end
end

---Find all $ref usages pointing at the definition/ref under the cursor.
---@param bufnr? integer
function M.find_references(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local ctx = context.at_cursor(bufnr)
  if not ctx.pointer or ctx.file then
    return lsp_fallback()
  end

  local model, err = parser.parse(bufnr)
  if not model then
    vim.notify("openapi: " .. (err or "parse failed"), vim.log.levels.WARN)
    return
  end

  -- Collect every internal ref whose pointer matches the target.
  local matches = {}
  for _, r in ipairs(model.refs) do
    if not r.file and r.pointer == ctx.pointer then
      matches[#matches + 1] = r
    end
  end

  if #matches == 0 then
    vim.notify("openapi: no references to " .. ctx.pointer, vim.log.levels.INFO)
    return
  end

  if #matches == 1 then
    util.jump(matches[1].pos, bufnr)
    return
  end

  M.show_picker(matches, bufnr, ctx.pointer)
end

---@param matches openapi.RefUse[]
---@param bufnr integer
---@param pointer string
function M.show_picker(matches, bufnr, pointer)
  local items = {}
  for _, r in ipairs(matches) do
    local line = vim.api.nvim_buf_get_lines(bufnr, r.pos.row - 1, r.pos.row, false)[1] or ""
    items[#items + 1] = {
      text = pointer .. " " .. line,
      line = vim.trim(line),
      buf = bufnr,
      pos = { r.pos.row, r.pos.col },
    }
  end

  if not util.has_snacks_picker() then
    vim.ui.select(items, {
      prompt = "References to " .. pointer,
      format_item = function(item)
        return string.format("%d: %s", item.pos[1], item.line)
      end,
    }, function(item)
      if item then
        util.jump({ row = item.pos[1], col = item.pos[2] }, item.buf)
      end
    end)
    return
  end

  Snacks.picker.pick({
    source = "openapi_references",
    title = "References to " .. pointer,
    items = items,
    format = function(item)
      ---@type snacks.picker.Highlight[]
      local ret = {}
      ret[#ret + 1] = { string.format("%4d  ", item.pos[1]), "LineNr" }
      ret[#ret + 1] = { item.line, "Normal" }
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

return M
