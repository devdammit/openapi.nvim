local M = {}

---@class openapi.Ref
---@field value string         Raw $ref value
---@field file string?         External file part (nil for internal refs)
---@field pointer string?      JSON pointer part without leading '#', e.g. "/components/schemas/User"

---Parse a raw $ref string into file + JSON pointer parts.
---Examples:
---  "#/components/schemas/User"      -> { pointer = "/components/schemas/User" }
---  "./schemas.yaml#/User"           -> { file = "./schemas.yaml", pointer = "/User" }
---  "./schemas/User.yaml"            -> { file = "./schemas/User.yaml" }
---@param value string
---@return openapi.Ref
function M.parse(value)
  value = vim.trim(value or "")
  local file, pointer = value:match("^([^#]*)#(.*)$")
  if file == nil then
    -- No '#': whole value is a file reference.
    return { value = value, file = value ~= "" and value or nil }
  end
  return {
    value = value,
    file = (file ~= "" and file) or nil,
    pointer = (pointer ~= "" and pointer) or nil,
  }
end

---Decode a JSON-pointer token per RFC 6901 (~1 -> '/', ~0 -> '~').
---@param token string
---@return string
local function decode_token(token)
  return (token:gsub("~1", "/"):gsub("~0", "~"))
end

---Split a JSON pointer into its decoded path segments.
---@param pointer string?  e.g. "/components/schemas/User"
---@return string[]
function M.pointer_segments(pointer)
  local segs = {}
  if not pointer or pointer == "" then
    return segs
  end
  for token in pointer:gmatch("[^/]+") do
    table.insert(segs, decode_token(token))
  end
  return segs
end

---True when the ref points within the current document (no external file).
---@param ref openapi.Ref
---@return boolean
function M.is_internal(ref)
  return ref.file == nil
end

return M
