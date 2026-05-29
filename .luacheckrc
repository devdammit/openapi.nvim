-- luacheck configuration for openapi.nvim
std = "luajit"
cache = true
codes = true

-- `vim` is writable (we set vim.g.* flags), so declare it as a mutable global
-- with known writable fields rather than read-only.
globals = {
  "vim.g",
}

-- Globals provided by the Neovim runtime / plugins (read-only).
read_globals = {
  "vim",
  "Snacks",
}

-- Neovim's API frequently produces long lines; relax the limit.
max_line_length = 120

exclude_files = {
  ".luarocks",
}
