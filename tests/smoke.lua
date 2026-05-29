-- Headless smoke test for openapi.nvim.
-- Run with:
--   nvim --headless -u tests/minimal_init.lua -l tests/smoke.lua
-- Exits non-zero on the first failed assertion.

local errors = 0

local function check(cond, msg)
  if cond then
    io.write("ok   - " .. msg .. "\n")
  else
    io.write("FAIL - " .. msg .. "\n")
    errors = errors + 1
  end
end

-- Resolve fixture relative to this script.
local fixture = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h") .. "/fixtures/petstore.yaml"

require("openapi").setup({})

vim.cmd("edit " .. vim.fn.fnameescape(fixture))
vim.bo.filetype = "yaml"
vim.api.nvim_exec_autocmds("FileType", { buffer = 0 })

-- 1. Parser model.
local model, err = require("openapi.parser").parse(0)
check(model ~= nil, "parser returns a model (" .. tostring(err) .. ")")
if model then
  check(#model.operations == 3, "3 operations parsed (got " .. #model.operations .. ")")
  check(#model.components == 4, "4 components parsed (got " .. #model.components .. ")")
  check(#model.refs == 3, "3 refs parsed (got " .. #model.refs .. ")")
  check(model.targets["/components/schemas/User"] ~= nil, "target index contains /components/schemas/User")
end

-- 2. Go to declaration: cursor on the User $ref (line 14) jumps to def (line 31).
vim.api.nvim_win_set_cursor(0, { 14, 20 })
require("openapi.nav.declaration").goto_declaration(0)
check(vim.api.nvim_win_get_cursor(0)[1] == 31, "gd jumps from $ref to definition (line 31)")

-- 3. References: Pet has 2 usages.
local pet_refs = 0
for _, r in ipairs(model.refs) do
  if r.pointer == "/components/schemas/Pet" then
    pet_refs = pet_refs + 1
  end
end
check(pet_refs == 2, "Pet has 2 references (got " .. pet_refs .. ")")

-- 4. Highlight extmark placed on the $ref under the cursor.
require("openapi.highlight").attach(0)
vim.api.nvim_win_set_cursor(0, { 14, 25 })
require("openapi.highlight").refresh(0)
local ns = vim.api.nvim_create_namespace("openapi_ref_highlight")
local marks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
check(#marks == 1, "highlight extmark placed on $ref under cursor")

-- 5. Highlight cleared when cursor leaves the $ref.
vim.api.nvim_win_set_cursor(0, { 1, 0 })
require("openapi.highlight").refresh(0)
check(#vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) == 0, "highlight cleared off $ref")

if errors > 0 then
  io.write(("\n%d assertion(s) failed\n"):format(errors))
  vim.cmd("cquit 1")
else
  io.write("\nall smoke checks passed\n")
  vim.cmd("quitall")
end
