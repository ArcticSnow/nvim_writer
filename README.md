# nvim_writer

An independent Neovim config for long-form writing: Markdown and Typst
articles, backed by BibTeX references. Runs side by side with your main
(coding) config via `NVIM_APPNAME`.

## Philosophy

Sober, minimalist, practical. Small personally-tuned modules (`lua/custom/`)
over large multi-purpose plugins wherever that's reasonable -- 17 plugins
total.

## What actually broke, and what fixed it

Two real bugs, found from your reports, not guessed at:

1. **Wrong URL**: `lua/plugins/typst.lua` had `mason-org/mason-tool-
   installer.nvim`. That plugin was never moved to the `mason-org` GitHub
   org (only `mason.nvim` and `mason-lspconfig.nvim` were) -- it's still
   `WhoIsSethDaniel/mason-tool-installer.nvim`. Fixed.

2. **A crash in my own hand-rolled Typst query-fetcher**: I'd written a
   function that cloned a grammar repo in the background and copied its
   query files into place. Its error-handling path correctly deferred to
   `vim.schedule()` (required when calling Vim/Lua APIs from an async
   callback), but its *success* path called `vim.fn.mkdir()` directly,
   un-deferred -- `E5560: Vimscript function "mkdir" must not be called in a
   fast event context`. Worse: because that callback fired asynchronously,
   at an unpredictable moment, its uncaught error could land in the middle
   of *any* other plugin module's install that happened to be in flight at
   that moment -- which is why oil/telescope/mini/auto-session/misc/obsidian
   all reported "failed to load" too, not just typst.

   The real fix wasn't patching that function -- it was **deleting it**.
   While tracking this down I found that a new community org,
   [neovim-treesitter](https://github.com/neovim-treesitter), now maintains
   an official parser+queries registry that lists Typst as a normal entry
   (parser: `uben0/tree-sitter-typst` -- confirms the grammar I'd already
   picked; queries: a dedicated `nvim-treesitter-queries-typst` repo). A
   current nvim-treesitter `main`-branch checkout should install both
   automatically from a plain `:TSInstall typst`, same as any other
   language -- no manual registration, no hand-rolled query-fetching. So
   `lua/plugins/treesitter.lua` just adds `'typst'` to the normal
   `ensure_installed` list now, each language installed in its own `pcall`
   so one bad entry can't take the others down. If `:TSInstall typst`
   doesn't work for you, that means your nvim-treesitter predates this
   registry integration -- check the registry repo directly rather than
   trust a third hand-rolled guess from me.

`lua/config/pack.lua` also installs and configures each plugin module in
its own `pcall`, independent of the above -- defense in depth, so a future
bad spec anywhere reports via `vim.notify` instead of cascading.

## Typst support

- **LSP**: `tinymist` via Mason, `formatterMode = "typstyle"`,
  `exportPdf = "onType"` (a continuously fresh compiled PDF -- used by the
  `<leader>tv` manual-viewer fallback below).
- **Completion**: Neovim's native `vim.lsp.completion`, autotriggered.
- **Treesitter**: `'typst'` in the normal parser list (see above).
- **Live preview**: `lua/plugins/typst_preview.lua`, via
  [`typst-preview.nvim`](https://github.com/chomosuke/typst-preview.nvim) --
  a browser tab that updates on every keystroke (true incremental SVG
  rendering, not a screenshot) with cursor sync in both directions: move
  around in Neovim and the preview scrolls to match; click in the preview
  and it jumps your cursor in Neovim. This is the one place in this whole
  config using a real plugin dependency instead of a `lua/custom/` module --
  it talks to tinymist's own preview protocol directly (task IDs, SVG frame
  diffing, a known tinymist config-reload race), which isn't something to
  responsibly hand-roll. Configured to use the `tinymist` Mason already
  installs rather than downloading a second copy. Needs `curl` (for its own
  first-run binary fetch -- almost certainly already on your system).
  **Replaces** an earlier Kitty-window version (rasterize the PDF, show it
  in a companion terminal window) that's been removed -- that one is still
  a reasonable pattern if you ever want a terminal-native, no-browser
  option again; ask and I can rebuild it.

## What's here

- **Citations**: `lua/custom/bibtex_finder.lua`, automatic `[@key]`/`@key`
  format switching, hover preview.
- **The room**: `lua/custom/prose_mode.lua` -- centered column, chrome
  hidden.
- **The sentence**: `lua/custom/paragraph_focus.lua` -- dims other
  paragraphs.
- **The type**: `lua/custom/smart_typography.lua` -- smart dashes/ellipses/
  quotes, Markdown only.
- **The overview**: `lua/custom/outline_panel.lua` -- toggleable side
  panel, follows the active buffer.
- **Files**: `oil.nvim`.
- **Kitty ambiance** (optional): `lua/custom/kitty_room.lua`.

## Keymaps

| Key | Action |
|---|---|
| `<leader>zz` | Toggle write mode (room + paragraph focus + Kitty ambiance) |
| `<leader>zf` | Toggle paragraph-focus dimming on its own |
| `<leader>zt` | Toggle typographic autocorrect on its own |
| `<leader>zb` | Toggle light/dark background |
| `<leader>to` | Toggle the outline side panel |
| `<leader>tp` | Toggle Typst live preview (browser, cursor-synced) |
| `<leader>tv` | Open compiled PDF in the system viewer (manual fallback) |
| `<leader>tc` | Force-compile Typst (manual fallback) |
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

First launch installs every plugin -- needs network, and will `vim.notify`
if any single one fails rather than refusing to start.

## Left for later

- **Word-count session log** -- low priority, optional.
- **`set-spacing` line-height bump** in `kitty_room.lua` -- the command
  exists, I didn't want to ship unconfirmed argument syntax. Check
  `kitten @ set-spacing -h`.

## Known rough edges

- **Typst treesitter support depends on your nvim-treesitter checkout
  consuming the neovim-treesitter registry** -- see "What actually broke"
  above. If it doesn't, you'll get no Typst highlighting (not a crash --
  the install is `pcall`'d per-language), and you'll need to check that
  registry's docs directly for whatever the current manual approach is.
- **`prose_mode.lua`'s pad windows** are non-modifiable but not
  un-enterable -- `<C-w>h`/`<C-w>l` can still focus them.
- **`kitty_room.lua`'s font-size toggle is a relative +2/-2**, not a
  save-and-restore -- Kitty's remote-control protocol doesn't expose a
  "get current font size" query I could confirm. Self-corrects as long as
  enable/disable stay paired.
- **Every async callback in this config that calls a Vim/Lua API has been
  re-audited for the exact "fast event context" bug class that caused the
  mkdir crash** (`grep -n "vim.system(" lua/**/*.lua` and checked each one
  by hand) -- but I still can't runtime-test any of this myself, so "traced
  it by hand and it looks right" is the ceiling of my confidence, not "ran
  it end-to-end."
