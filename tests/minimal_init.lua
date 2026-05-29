-- Minimal init for headless tests / CI.
--
-- The plugin only needs the `yaml` treesitter parser available as
-- `parser/yaml.so` on the runtimepath -- it uses the core `vim.treesitter` API
-- directly, not nvim-treesitter modules. So instead of depending on
-- nvim-treesitter's installer (which is brittle in CI), we compile the
-- tree-sitter-yaml grammar from source into <deps>/parser/yaml.so.

local uv = vim.uv or vim.loop

local function root(suffix)
  local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
  return plugin_dir .. (suffix or "")
end

local function exists(path)
  return uv.fs_stat(path) ~= nil
end

local function run(cmd)
  local obj = vim.system(cmd, { text = true }):wait()
  if obj.code ~= 0 then
    io.stderr:write(("command failed (%d): %s\n%s\n"):format(obj.code, table.concat(cmd, " "), obj.stderr or ""))
  end
  return obj.code == 0
end

-- Where to keep test dependencies.
local deps = os.getenv("OPENAPI_TEST_DEPS") or (vim.fn.stdpath("data") .. "/openapi-test-deps")
vim.fn.mkdir(deps .. "/parser", "p")

local parser_so = deps .. "/parser/yaml.so"

if not exists(parser_so) then
  local src = deps .. "/tree-sitter-yaml"
  if not exists(src) then
    if
      not run({
        "git",
        "clone",
        "--depth",
        "1",
        "https://github.com/tree-sitter-grammars/tree-sitter-yaml",
        src,
      })
    then
      io.stderr:write("FATAL: failed to clone tree-sitter-yaml\n")
      vim.cmd("cquit 1")
    end
  end

  -- tree-sitter-yaml ships a C parser and a C scanner (the scanner pulls in the
  -- default `schema.core.c` itself via an #include), so everything is plain C.
  local cc = os.getenv("CC") or "cc"
  local srcdir = src .. "/src"

  local ok = run({ cc, "-c", "-fPIC", "-I", srcdir, srcdir .. "/scanner.c", "-o", deps .. "/scanner.o" })
  ok = ok and run({ cc, "-c", "-fPIC", "-I", srcdir, srcdir .. "/parser.c", "-o", deps .. "/parser.o" })
  ok = ok
    and run({
      cc,
      "-shared",
      "-fPIC",
      deps .. "/parser.o",
      deps .. "/scanner.o",
      "-o",
      parser_so,
    })

  if not ok or not exists(parser_so) then
    io.stderr:write("FATAL: failed to build the yaml treesitter parser\n")
    vim.cmd("cquit 1")
  end
end

-- Put the compiled parser and this plugin on the runtimepath.
vim.opt.runtimepath:prepend(deps)
vim.opt.runtimepath:prepend(root())

-- Sanity check: the yaml parser must load.
if not pcall(vim.treesitter.language.add, "yaml") then
  io.stderr:write("FATAL: yaml treesitter parser is not available\n")
  vim.cmd("cquit 1")
end
