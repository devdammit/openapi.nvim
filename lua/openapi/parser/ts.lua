local M = {}

---Get the YAML treesitter root node for a buffer, or nil if unavailable.
---@param bufnr integer
---@return TSNode? root, vim.treesitter.LanguageTree? parser
function M.root(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "yaml")
  if not ok or not parser then
    return nil, nil
  end
  local trees = parser:parse()
  if not trees or not trees[1] then
    return nil, parser
  end
  return trees[1]:root(), parser
end

---Return the text covered by a node.
---@param node TSNode
---@param bufnr integer
---@return string
function M.node_text(node, bufnr)
  return vim.treesitter.get_node_text(node, bufnr)
end

---Strip surrounding quotes from a scalar value.
---@param s string
---@return string
function M.unquote(s)
  if not s then
    return s
  end
  local first = s:sub(1, 1)
  if (first == '"' or first == "'") and s:sub(-1) == first then
    return s:sub(2, -2)
  end
  return s
end

---Extract the scalar string from a key/value node, unwrapping flow_node /
---plain_scalar / single_quote_scalar / double_quote_scalar wrappers.
---@param node TSNode?
---@param bufnr integer
---@return string?
function M.scalar_text(node, bufnr)
  if not node then
    return nil
  end
  local t = node:type()
  if t == "flow_node" or t == "block_node" then
    -- descend into the single child scalar
    local child = node:named_child(0)
    if child then
      return M.scalar_text(child, bufnr)
    end
    return M.unquote(M.node_text(node, bufnr))
  end
  return M.unquote(M.node_text(node, bufnr))
end

---Iterate over key/value pairs of a mapping-bearing node.
---Accepts a block_mapping, block_node wrapping a block_mapping, or flow_mapping.
---@param node TSNode?
---@param bufnr integer
---@return fun(): TSNode?, TSNode?, string?  iterator yielding (key_node, value_node, key_text)
function M.iter_pairs(node, bufnr)
  local mapping = M.as_mapping(node)
  if not mapping then
    return function() end
  end

  local idx = 0
  local count = mapping:named_child_count()
  return function()
    while idx < count do
      local pair = mapping:named_child(idx)
      idx = idx + 1
      if pair and (pair:type() == "block_mapping_pair" or pair:type() == "flow_pair") then
        local key = pair:field("key")[1]
        local value = pair:field("value")[1]
        local key_text = M.scalar_text(key, bufnr)
        return key, value, key_text
      end
    end
    return nil
  end
end

---Resolve a node down to its underlying mapping node, if any.
---@param node TSNode?
---@return TSNode? mapping
function M.as_mapping(node)
  if not node then
    return nil
  end
  local t = node:type()
  if t == "block_mapping" or t == "flow_mapping" then
    return node
  end
  if t == "block_node" or t == "flow_node" then
    for i = 0, node:named_child_count() - 1 do
      local child = node:named_child(i)
      local ct = child:type()
      if ct == "block_mapping" or ct == "flow_mapping" then
        return child
      end
    end
  end
  return nil
end

---Find the value node for a given key within a mapping-bearing node.
---@param node TSNode?
---@param bufnr integer
---@param key string
---@return TSNode? value_node, TSNode? key_node
function M.get(node, bufnr, key)
  for k, v, kt in M.iter_pairs(node, bufnr) do
    if kt == key then
      return v, k
    end
  end
  return nil, nil
end

---Convert a node's start position to a 1-based (row, col) for cursor placement.
---@param node TSNode
---@return integer row1, integer col0  -- row is 1-based, col is 0-based
function M.pos(node)
  local r, c = node:start()
  return r + 1, c
end

return M
