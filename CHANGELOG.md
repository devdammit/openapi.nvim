# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Operations picker (`:OpenapiOperations`, `<leader>oo`) listing every
  `METHOD /path` with its `operationId` and `summary`.
- Components picker (`:OpenapiComponents [kind]`, `:OpenapiSchemas`,
  `<leader>os`) covering all `components.*` kinds, with optional kind filter.
- Go to declaration (`gd`) from a `$ref` to its definition, with fallback to
  the default LSP definition behaviour.
- Find references (`gr`) from a component definition or `$ref`, with fallback
  to the default LSP references behaviour.
- `$ref`-under-cursor highlight via the `OpenapiRefUnderCursor` group.
- Buffer-local detection of OpenAPI / Swagger YAML specs; keymaps and commands
  are scoped to detected buffers only.
- Per-buffer model cache keyed by `changedtick`.

[Unreleased]: https://github.com/devdammit/openapi.nvim/commits/main
