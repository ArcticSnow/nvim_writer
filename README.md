# nvim_writer

An independent Neovim config for long-form writing: Markdown and Typst
articles, backed by BibTeX references. Runs side by side with your main
(coding) config via `NVIM_APPNAME` -- see "Install" below.

## Philosophy

Sober, minimalist, practical. The page should feel like paper, the cursor
like a pen, and the machinery (LSP, citations, compilation) should stay
invisible until you actually need it. Small personally-tuned modules
(`lua/custom/`) over large multi-purpose plugins wherever that's reasonable
-- 17 plugins total.

## About the crash you hit

`Error ... E5113 ... vim.pack: mason-tool-installer.nvim: fatal: could not
read Username for 'https://github.com'` was a wrong URL on my part:
`lua/plugins/typst.lua` had `mason-org/mason-tool-installer.nvim`, but that
plugin was never moved to the `mason-org` GitHub org (only `mason.nvim` and
`mason-lspconfig.nvim` were) -- it's still `WhoIsSethDaniel/mason-tool-
installer.nvim`. Fixed.

More importantly: `vim.pack.add()` fails **atomically** -- one bad spec in
the array throws and aborts the *entire* call, including every plugin listed
before or after it. Everything was installed in one combined call, so this
one wrong URL was enough to stop `oil.nvim` (and Telescope, mini.nvim,
everything else) from ever installing too, even though their own specs were
completely fine -- which is why oil looked "missing" even though it was (and
still is) fully configured in `lua/plugins/oil.lua`. `lua/config/pack.lua`
now installs and configures each plugin module in its own `pcall`'d call, so
a failure in one module gets reported via `vim.notify` instead of silently
taking every other plugin down with it.

## Typst, now fully implemented

- **LSP**: `tinymist` via Mason (URL fixed, see above), with
  `formatterMode = "typstyle"` and `exportPdf = "onType"` (a continuously
  fresh compiled PDF, which the preview below builds on).
- **Completion**: Neovim's native `vim.lsp.completion`, autotriggered --
  still no completion-engine plugin needed.
- **Treesitter**: switched from `frozolotl/tree-sitter-typst` (last pass) to
  `uben0/tree-sitter-typst` -- more complete (markup/code/math modes,
  indentation, folding all implemented; frozolotl's is still missing code
  mode, lists, enums, terms) and more established (189 stars/239 commits vs.
  77/83). **The piece that was actually missing last time**: registering a
  custom parser only gets you the compiled grammar -- Neovim also needs
  *query files* (`queries/typst/highlights.scm` etc.) to highlight anything
  with it, and nvim-treesitter doesn't fetch those for unlisted parsers.
  `lua/plugins/treesitter.lua`'s `ensure_typst_queries()` now fetches them
  itself (a small background git clone, self-healing -- retries next startup
  if it fails), so highlighting should genuinely work now, not just install
  a parser that has nothing to highlight with.
- **Live preview**: new, `lua/custom/typst_preview.lua`. Watches the PDF
  `exportPdf = "onType"` keeps fresh, rasterizes the current page, and shows
  it in a companion Kitty window via Kitty's remote-control protocol (same
  mechanism as `kitty_room.lua`). Debounced (500ms) so fast typing doesn't
  reopen the window on every keystroke. Needs `pdftoppm` (poppler-utils).
  Stated trade-off in that file's header: each refresh closes and reopens
  the preview window rather than updating it in place -- a little flicker,
  but built only from Kitty commands I could directly confirm exist, rather
  than the smoother overlay mechanism I couldn't verify confidently enough
  to ship.

## What's here

- **Citations**: `lua/custom/bibtex_finder.lua`, with automatic `[@key]`
  (Markdown) / `@key` (Typst) format switching and a hover-style preview.
- **The room**: `lua/custom/prose_mode.lua` -- a centered column, chrome
  hidden, built from the goyo.vim technique but from scratch.
- **The sentence**: `lua/custom/paragraph_focus.lua` -- dims every paragraph
  except the one you're in.
- **The type**: `lua/custom/smart_typography.lua` -- smart dashes, ellipses,
  curly quotes as you type, Markdown only (Typst renders its own).
- **The overview**: `lua/custom/outline_panel.lua` -- a toggleable side
  panel that follows the active buffer and tracks your position in it.
- **Files**: `oil.nvim` -- takes over the buffer instead of sitting as a
  permanent sidebar.
- **Kitty ambiance** (optional, best-effort): `lua/custom/kitty_room.lua`
  nudges Kitty's font size when write mode turns on.

## Keymaps

| Key | Action |
|---|---|
| `<leader>zz` | Toggle write mode (room + paragraph focus + Kitty ambiance) |
| `<leader>zf` | Toggle paragraph-focus dimming on its own |
| `<leader>zt` | Toggle typographic autocorrect on its own |
| `<leader>zb` | Toggle light/dark background |
| `<leader>to` | Toggle the outline side panel |
| `<leader>tp` | Toggle Typst live preview (Kitty) |
| `]p` / `[p` | Typst preview: next / previous page |
| `<leader>tv` | Open compiled PDF in the system viewer |
| `<leader>tc` | Force-compile Typst (manual fallback; tinymist compiles internally otherwise) |
| `<leader>bb` | Insert a citation |
| `<leader>bz` | Select a different `.bib` file |
| `<leader>bp` | Preview the citation under the cursor (also automatic on hover) |
| `<leader>ff` / `<leader>fg` / `<leader>fb` | Find files / live grep / buffers |
| `-` / `+` | Open parent directory (oil.nvim) / floating |
| `grn` / `gra` / `grd` / `grr` / `gO` / `K` | LSP: rename / code action / definition / references / doc symbols / hover |

## Install

```sh
git clone <this repo> ~/.config/nvim_writer
NVIM_APPNAME=nvim_writer nvim path/to/article.md
```

First launch installs every plugin -- needs network, takes a bit, and will
`vim.notify` if any single one fails rather than refusing to start. Consider
a shell alias:

```sh
alias vimw='NVIM_APPNAME=nvim_writer nvim'
```

## Left for later

- **Word-count session log** -- a quiet trace of words-written-per-day per
  file. Low priority, purely optional.
- **`set-spacing` line-height bump** in `kitty_room.lua` -- the command
  exists in Kitty's remote-control protocol, I just didn't want to ship
  argument syntax I hadn't confirmed. Check `kitten @ set-spacing -h` and
  extend `M.enable()`/`M.disable()` there.
- **A smoother in-place preview update** -- `typst_preview.lua`'s
  close/reopen approach works but flickers a little; Kitty's
  `--type=overlay` launch mode might update in place instead. Worth
  revisiting if the flicker bothers you in practice.

## Known rough edges

- **Typst treesitter support is a community grammar**, not an official/
  bundled one -- the whole Typst-in-Neovim ecosystem is genuinely unsettled.
  If highlighting looks wrong or breaks on an update, `lua/plugins/
  treesitter.lua` is the first place to look; swap `TYPST_GRAMMAR_URL` for a
  different grammar if needed.
- **`prose_mode.lua`'s pad windows** are non-modifiable but not
  un-enterable -- `<C-w>h`/`<C-w>l` can still focus them. Harmless, not
  fully guarded against.
- **`kitty_room.lua`'s font-size toggle is a relative +2/-2**, not a
  save-and-restore of your actual size -- Kitty's remote-control protocol
  doesn't expose a "get current font size" query I could confirm.
  Self-corrects as long as enable/disable stay paired.
- **Every `vim.pack` git URL in this config has now been individually
  verified** against its actual GitHub repo (not just recalled from memory)
  after the mason-tool-installer mistake -- but I can't runtime-test git
  clones or Kitty remote-control calls in the environment I build this in,
  so "verified the URL/command exists" is the ceiling of my confidence, not
  "ran it end-to-end."
