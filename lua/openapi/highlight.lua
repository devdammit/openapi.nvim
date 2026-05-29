local ts = require("openapi.parser.ts")

local M = {}

local NS = vim.api.nvim_create_namespace("openapi_ref_highlight")
local HL_GROUP = "OpenapiRefUnderCursor"

-- Buffers we've already wired CursorMoved autocmds for.
local wired = {}

---Define the highlight group: active accent colour + underline.
---Uses `default = true` so a user's colorscheme or config can override it.
local function ensure_hl()
  -- Borrow an accent foreground from an existing "link"-like group.
  local accent = vim.api.nvim_get_hl(0, { name = "Underlined", link = false })
  local fg = accent and accent.fg or nil
  vim.api.nvim_set_hl(0, HL_GROUP, {
    underline = true,
    bold = true,
    fg = fg,
    sp = fg,
    default = true,
  })
end

---Find the $ref value node enclosing the cursor (the scalar to highlight).
---@param bufnr integer
---@return TSNode? value_node
local function ref_value_node(bufnr)
  local node = vim.treesitter.get_node({ bufnr = bufnr })
  while node do
    if node:type() == "block_mapping_pair" or node:type() == "flow_pair" then
      local key = node:field("key")[1]
      local value = node:field("value")[1]
      if value and ts.scalar_text(key, bufnr) == "$ref" then
        -- Descend to the innermost scalar so we underline just the string,
        -- not the surrounding flow_node whitespace.
        local inner = value
        while inner:named_child_count() == 1 do
          local child = inner:named_child(0)
          local ctype = child:type()
          if ctype == "flow_node" or ctype == "single_quote_scalar" or ctype == "double_quote_scalar" then
            inner = child
          else
            break
          end
        end
        return inner
      end
    end
    node = node:parent()
  end
  return nil
end

---Refresh the highlight for the current cursor position in a buffer.
---@param bufnr integer
function M.refresh(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)

  local ok, p = pcall(vim.treesitter.get_parser, bufnr, "yaml")
  if not ok or not p then
    return
  end
  p:parse()

  local node = ref_value_node(bufnr)
  if not node then
    return
  end

  local srow, scol, erow, ecol = node:range()

  -- If the scalar is quoted, shrink the range by one column on each side so we
  -- underline only the pointer text, not the surrounding quotes.
  local text = ts.node_text(node, bufnr)
  if text then
    local first = text:sub(1, 1)
    if (first == '"' or first == "'") and text:sub(-1) == first and srow == erow then
      scol = scol + 1
      ecol = ecol - 1
    end
  end

  vim.api.nvim_buf_set_extmark(bufnr, NS, srow, scol, {
    end_row = erow,
    end_col = ecol,
    hl_group = HL_GROUP,
    priority = 200,
  })
end

---Wire up cursor-driven highlighting for an OpenAPI buffer.
---@param bufnr integer
function M.attach(bufnr)
  ensure_hl()
  if wired[bufnr] then
    M.refresh(bufnr)
    return
  end
  wired[bufnr] = true

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
    buffer = bufnr,
    callback = function()
      M.refresh(bufnr)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    buffer = bufnr,
    once = true,
    callback = function()
      wired[bufnr] = nil
    end,
  })

  -- Re-apply our hl group when the colorscheme changes.
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      ensure_hl()
    end,
  })

  M.refresh(bufnr)
end

return M
