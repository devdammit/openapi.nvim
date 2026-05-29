-- Minimal init for headless tests / CI.
-- Clones nvim-treesitter into a temp dir (if not already present), installs the
-- yaml parser, and puts this plugin on the runtimepath.

local function root(suffix)
  local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
  return plugin_dir .. (suffix or "")
end

-- Where to keep test dependencies.
local deps = os.getenv("OPENAPI_TEST_DEPS") or (vim.fn.stdpath("data") .. "/openapi-test-deps")
vim.fn.mkdir(deps, "p")

-- Use the stable `master` branch: it ships the classic synchronous parser
-- installer (`:TSInstallSync`). The plugin itself only needs the `yaml` parser
-- on the runtimepath -- it uses the core `vim.treesitter` API, not nvim-treesitter
-- modules -- so the branch choice only affects how we obtain that parser in CI.
local treesitter = deps .. "/nvim-treesitter"
if vim.fn.isdirectory(treesitter) == 0 then
  vim.fn.system({
    "git",
    "clone",
    "--branch",
    "master",
    "--filter=blob:none",
    "https://github.com/nvim-treesitter/nvim-treesitter",
    treesitter,
  })
end

-- Put deps and this plugin on the runtimepath.
vim.opt.runtimepath:prepend(treesitter)
vim.opt.runtimepath:prepend(root())

-- Install the yaml parser if missing.
if pcall(require, "nvim-treesitter.configs") then
  pcall(vim.cmd, "TSInstallSync! yaml")
end
