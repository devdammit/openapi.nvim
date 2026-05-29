local M = {}

---Jump the given window's cursor to a position, recording the jumplist.
---@param pos openapi.Pos  {row=1-based, col=0-based}
---@param bufnr? integer
function M.jump(pos, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  -- Record jump position in the jumplist before moving.
  vim.cmd("normal! m'")
  if bufnr ~= vim.api.nvim_get_current_buf() then
    vim.api.nvim_set_current_buf(bufnr)
  end
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local row = math.min(pos.row, line_count)
  vim.api.nvim_win_set_cursor(0, { row, pos.col or 0 })
  vim.cmd("normal! zz")
end

---True if Snacks.picker is available.
---@return boolean
function M.has_snacks_picker()
  return pcall(require, "snacks") and Snacks ~= nil and Snacks.picker ~= nil
end

return M
