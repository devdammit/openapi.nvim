local ts = require("openapi.parser.ts")

local M = {}

---@class openapi.Context
---@field kind "ref"|"component"|nil
---@field pointer string?   internal JSON pointer of the target/definition
---@field file string?      external file (for ref) if any
---@field ref openapi.Ref?  parsed ref when kind == "ref"

---Find the nearest enclosing block_mapping_pair whose key matches `$ref`,
---returning the raw ref value if the cursor sits on that pair.
---@param bufnr integer
---@return string? raw_ref
local function ref_at_cursor(bufnr)
  local node = vim.treesitter.get_node({ bufnr = bufnr })
  while node do
    if node:type() == "block_mapping_pair" or node:type() == "flow_pair" then
      local key = node:field("key")[1]
      local value = node:field("value")[1]
      if ts.scalar_text(key, bufnr) == "$ref" and value then
        return ts.scalar_text(value, bufnr)
      end
    end
    node = node:parent()
  end
  return nil
end

---Determine whether the cursor sits on a component definition key, returning
---its JSON pointer. Walks parent block_mapping_pair chain to build the path
---and matches `/components/<kind>/<name>`.
---@param bufnr integer
---@return string? pointer
local function component_at_cursor(bufnr)
  local node = vim.treesitter.get_node({ bufnr = bufnr })
  -- Build the key path from the cursor up to the document root.
  local keys = {}
  while node do
    if node:type() == "block_mapping_pair" or node:type() == "flow_pair" then
      local key = node:field("key")[1]
      local kt = ts.scalar_text(key, bufnr)
      if kt then
        table.insert(keys, 1, kt)
      end
    end
    node = node:parent()
  end
  -- keys is the path from root, e.g. {"components","schemas","User", ...}
  if keys[1] == "components" and keys[2] and keys[3] then
    return "/components/" .. keys[2] .. "/" .. keys[3]
  end
  return nil
end

---Resolve the navigation context at the cursor.
---@param bufnr integer
---@return openapi.Context
function M.at_cursor(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Ensure the YAML tree is parsed before querying nodes at the cursor.
  local ok, p = pcall(vim.treesitter.get_parser, bufnr, "yaml")
  if ok and p then
    p:parse()
  end

  local raw = ref_at_cursor(bufnr)
  if raw then
    local ref = require("openapi.parser.ref").parse(raw)
    return { kind = "ref", pointer = ref.pointer, file = ref.file, ref = ref }
  end

  local pointer = component_at_cursor(bufnr)
  if pointer then
    return { kind = "component", pointer = pointer }
  end

  return { kind = nil }
end

return M
