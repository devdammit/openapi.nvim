local M = {}

---@class openapi.Config
---@field keys table<string, string|false>
---@field components string[]|"all"
---@field detect_lines integer  How many leading lines to scan for openapi:/swagger:

---@type openapi.Config
local defaults = {
  keys = {
    declaration = "gd", -- go-to-declaration on $ref (falls back to LSP)
    references = "gr", -- find $ref usages (falls back to LSP)
    operations = "<leader>oo", -- operations picker
    components = "<leader>os", -- components picker
  },
  -- Which component kinds to index. "all" expands to every kind found.
  components = "all",
  detect_lines = 50,
}

M.ALL_COMPONENT_KINDS = {
  "schemas",
  "parameters",
  "responses",
  "requestBodies",
  "headers",
  "examples",
  "links",
  "callbacks",
  "securitySchemes",
  "pathItems",
}

---@type openapi.Config
M.options = vim.deepcopy(defaults)

---@param opts? openapi.Config
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  return M.options
end

return M
