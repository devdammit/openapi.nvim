# openapi.nvim

![Neovim](https://img.shields.io/badge/Neovim-0.10+-57A143?logo=neovim&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![CI](https://github.com/devdammit/openapi.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/devdammit/openapi.nvim/actions/workflows/ci.yml)
![Lua](https://img.shields.io/badge/Made%20with-Lua-2C2D72?logo=lua&logoColor=white)

Navigate OpenAPI / Swagger YAML specifications directly inside Neovim — no
Swagger UI, no external tools. List operations, fuzzy-find schemas and
components, and jump between `$ref` declarations and references just like you
would with LSP.

Built for [LazyVim](https://www.lazyvim.org/) (Neovim 0.10+), powered by
[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) for
parsing and [snacks.nvim](https://github.com/folke/snacks.nvim) for the picker
UI.

<!-- Record a short clip showing the operations picker, gd on a $ref, and the
     $ref highlight, then drop it at assets/demo.gif -->

![demo](assets/demo.gif)

## Features

- **Operations picker** — browse every `METHOD /path` with its `operationId`
  and `summary`.
- **Components picker** — fuzzy-search all `components.*` (schemas, parameters,
  responses, requestBodies, headers, examples, links, callbacks,
  securitySchemes, pathItems), optionally filtered by kind.
- **Go to declaration (`gd`)** — jump from a `$ref` to its definition.
- **Find references (`gr`)** — from a component definition (or a `$ref`), list
  every place that `$ref`s it.
- **`$ref` highlight** — the reference target under the cursor is underlined
  with an accent colour so you can see at a glance what you're about to follow.
- **Native keys, scoped to spec buffers** — `gd`/`gr` are remapped only in
  buffers detected as OpenAPI specs, and fall back to the default LSP behaviour
  when the cursor isn't on a `$ref` or a component definition.

## Requirements

- **Neovim 0.10+**.
- The `yaml` treesitter parser (`:TSInstall yaml` via nvim-treesitter).
- `snacks.nvim` (bundled with LazyVim) for the picker UI. Without it the plugin
  falls back to `vim.ui.select`.

## Installation

### lazy.nvim

```lua
-- ~/.config/nvim/lua/plugins/openapi.lua
return {
  {
    "devdammit/openapi.nvim",
    ft = "yaml",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
  },
}
```

### Local development

```lua
return {
  {
    dir = "~/path/to/openapi.nvim",
    ft = "yaml",
    opts = {},
  },
}
```

## Configuration

Defaults are shown below — pass any subset via `opts`:

```lua
opts = {
  keys = {
    declaration = "gd",          -- go to declaration on $ref
    references  = "gr",          -- find $ref usages
    operations  = "<leader>oo",  -- operations picker
    components  = "<leader>os",  -- components picker
  },
  -- Component kinds to index ("all" indexes every kind that appears).
  components = "all",
  -- How many leading lines to scan for `openapi:`/`swagger:` when detecting a spec.
  detect_lines = 50,
}
```

Set any key to `false` to disable that mapping.

## Commands

These are created buffer-locally in detected OpenAPI buffers:

| Command                     | Description                                       |
| --------------------------- | ------------------------------------------------- |
| `:OpenapiOperations`        | Open the operations picker                        |
| `:OpenapiComponents [kind]` | Open the components picker (optional kind filter) |
| `:OpenapiSchemas`           | Components picker filtered to `schemas`           |
| `:OpenapiReferences`        | Find references to the target under the cursor    |

## Highlights

The `$ref` value under the cursor is highlighted with the `OpenapiRefUnderCursor`
group (underline + bold + accent colour). It is defined with `default = true`,
so your colorscheme or config can override it:

```lua
vim.api.nvim_set_hl(0, "OpenapiRefUnderCursor", {
  underline = true,
  fg = "#7aa2f7",
})
```

## How detection works

A buffer is treated as an OpenAPI spec when it has `filetype=yaml` and one of
its first `detect_lines` lines contains a top-level `openapi:` or `swagger:`
key. Regular YAML files are left untouched.

## Notes & limitations

- **YAML only.** JSON specs are not parsed.
- **Single-file `$ref` only (for now).** Internal refs (`#/components/...`) are
  fully supported. External / multi-file refs (`./schemas/User.yaml#/...`) are
  detected but navigation across files is not implemented yet — `gd` on an
  external ref reports that it's unsupported rather than guessing.
- Parsing is resilient to partially-invalid YAML (e.g. while you're mid-edit):
  whatever treesitter can recover is indexed.

## Alternatives

- [armsnyder/openapi-language-server](https://github.com/armsnyder/openapi-language-server)
  — a standalone LSP server providing jump-to-definition / find-references for
  OpenAPI. `openapi.nvim` does this natively in-process via treesitter, with no
  separate server, plus snacks pickers and `$ref` highlighting.
- [codeasashu/oas.nvim](https://github.com/codeasashu/oas.nvim) — focuses on
  rendering previews (Redoc) rather than in-editor navigation.

## Development

```sh
# format check
stylua --check lua/ plugin/

# lint
luacheck lua/ plugin/
```

There is no test framework dependency: the CI runs a headless Neovim smoke test
that parses a sample spec and asserts the model, navigation, and highlight
behaviour. See `.github/workflows/ci.yml`.

## Architecture

```
lua/openapi/
  init.lua            setup() + FileType / LspAttach autocmds
  config.lua          defaults + merge
  detect.lua          is_openapi_buf()
  attach.lua          buffer-local keymaps + commands
  highlight.lua       $ref-under-cursor highlight
  cache.lua           per-buffer model cache (keyed by changedtick)
  util.lua            jump + picker availability
  parser/
    init.lua          parse(bufnr) -> model (cached)
    ts.lua            YAML AST traversal helpers
    model.lua         operations / components / refs / targets
    ref.lua           $ref parsing + JSON-pointer handling
  nav/
    context.lua       resolve target under the cursor
    declaration.lua   gd
    reference.lua     gr
  pickers/
    operations.lua
    components.lua
```

## License

[MIT](./LICENSE)
