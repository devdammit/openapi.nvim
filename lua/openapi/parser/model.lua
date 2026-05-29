local ts = require("openapi.parser.ts")

local M = {}

local HTTP_METHODS = {
  get = true,
  put = true,
  post = true,
  delete = true,
  options = true,
  head = true,
  patch = true,
  trace = true,
}

---@class openapi.Pos
---@field row integer  1-based line
---@field col integer  0-based column

---@class openapi.Operation
---@field method string        upper-cased HTTP method
---@field path string
---@field operationId string?
---@field summary string?
---@field pos openapi.Pos      position of the method key

---@class openapi.Component
---@field kind string          e.g. "schemas"
---@field name string
---@field pointer string       e.g. "/components/schemas/User"
---@field pos openapi.Pos      position of the component name key

---@class openapi.RefUse
---@field value string         raw $ref value
---@field pointer string?      internal JSON pointer (nil if external)
---@field file string?         external file (nil if internal)
---@field pos openapi.Pos      position of the $ref value node

---@class openapi.Model
---@field bufnr integer
---@field operations openapi.Operation[]
---@field components openapi.Component[]
---@field refs openapi.RefUse[]
---@field targets table<string, openapi.Pos>  pointer -> position of definition

local function mkpos(node)
  local row, col = ts.pos(node)
  return { row = row, col = col }
end

---Parse the paths section into operations.
---@param paths_node TSNode?
---@param bufnr integer
---@param ops openapi.Operation[]
local function parse_paths(paths_node, bufnr, ops)
  if not paths_node then
    return
  end
  for path_key, path_val, path_text in ts.iter_pairs(paths_node, bufnr) do
    if path_text and path_text:sub(1, 1) == "/" then
      for m_key, _, m_text in ts.iter_pairs(path_val, bufnr) do
        if m_text and HTTP_METHODS[m_text:lower()] then
          local op_val = select(1, ts.get(path_val, bufnr, m_text))
          local operationId = op_val and ts.scalar_text(select(1, ts.get(op_val, bufnr, "operationId")), bufnr)
          local summary = op_val and ts.scalar_text(select(1, ts.get(op_val, bufnr, "summary")), bufnr)
          table.insert(ops, {
            method = m_text:upper(),
            path = path_text,
            operationId = operationId,
            summary = summary,
            pos = mkpos(m_key),
          })
        end
      end
    end
  end
end

---Parse components.<kind>.<Name> entries.
---@param components_node TSNode?
---@param bufnr integer
---@param comps openapi.Component[]
---@param targets table<string, openapi.Pos>
local function parse_components(components_node, bufnr, comps, targets)
  if not components_node then
    return
  end
  for _kind_key, kind_val, kind_text in ts.iter_pairs(components_node, bufnr) do
    if kind_text then
      for name_key, _name_val, name_text in ts.iter_pairs(kind_val, bufnr) do
        if name_text then
          local pointer = "/components/" .. kind_text .. "/" .. name_text
          local pos = mkpos(name_key)
          table.insert(comps, {
            kind = kind_text,
            name = name_text,
            pointer = pointer,
            pos = pos,
          })
          targets[pointer] = pos
        end
      end
    end
  end
end

---Walk the whole tree collecting every $ref node.
---@param root TSNode
---@param bufnr integer
---@param refs openapi.RefUse[]
local function collect_refs(root, bufnr, refs)
  local parse_ref = require("openapi.parser.ref").parse

  -- Walk all block_mapping_pair / flow_pair nodes looking for key == "$ref".
  local function visit(node)
    for i = 0, node:named_child_count() - 1 do
      local child = node:named_child(i)
      local t = child:type()
      if t == "block_mapping_pair" or t == "flow_pair" then
        local key = child:field("key")[1]
        local value = child:field("value")[1]
        local key_text = ts.scalar_text(key, bufnr)
        if key_text == "$ref" and value then
          local raw = ts.scalar_text(value, bufnr)
          if raw then
            local parsed = parse_ref(raw)
            table.insert(refs, {
              value = raw,
              pointer = parsed.pointer,
              file = parsed.file,
              pos = mkpos(value),
            })
          end
        end
      end
      visit(child)
    end
  end

  visit(root)
end

---Build the full model from a buffer.
---@param bufnr integer
---@return openapi.Model? model, string? err
function M.build(bufnr)
  local root = ts.root(bufnr)
  if not root then
    return nil, "treesitter YAML parser unavailable"
  end

  local model = {
    bufnr = bufnr,
    operations = {},
    components = {},
    refs = {},
    targets = {},
  }

  -- Top-level mapping (document -> block_node -> block_mapping).
  local doc_mapping
  for i = 0, root:named_child_count() - 1 do
    local child = root:named_child(i)
    if child:type() == "document" then
      doc_mapping = child:named_child(0)
      break
    end
  end
  doc_mapping = doc_mapping or root

  local paths_node = select(1, ts.get(doc_mapping, bufnr, "paths"))
  local components_node = select(1, ts.get(doc_mapping, bufnr, "components"))

  parse_paths(paths_node, bufnr, model.operations)
  parse_components(components_node, bufnr, model.components, model.targets)
  collect_refs(root, bufnr, model.refs)

  return model, nil
end

return M
