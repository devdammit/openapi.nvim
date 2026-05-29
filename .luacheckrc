-- luacheck configuration for openapi.nvim
std = "luajit"
cache = true
codes = true

-- Globals provided by the Neovim runtime / plugins.
read_globals = {
  "vim",
  "Snacks",
}

-- Neovim's API frequently produces long lines; relax the limit.
max_line_length = 120

exclude_files = {
  ".luarocks",
}
