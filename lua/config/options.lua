-- ============================================================================
-- Base options. Unlike a code-editing config, these are calm BY DEFAULT --
-- lua/custom/prose_mode.lua adds the centered column and paragraph dimming on
-- top when toggled, but you shouldn't need it just to feel at ease in here.
-- ============================================================================

local set = vim.opt

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- ---------------------------------------------------------------------------
-- Chrome: minimal from the start. No line numbers, no sign column clutter,
-- no cursorline -- this isn't code, there's nothing to line up against.
-- ---------------------------------------------------------------------------
set.number = false
set.relativenumber = false
set.cursorline = false
set.signcolumn = 'no'
set.showmode = false -- the statusline already says it (see below)
set.ruler = false
set.showcmd = false
set.cmdheight = 1

-- Native minimal statusline instead of a statusline plugin: filename, modified
-- flag, word count, cursor position. Nothing else. See WriterStatusline() at
-- the bottom of this file.
set.laststatus = 2
vim.o.statusline = '%!v:lua.WriterStatusline()'

-- ---------------------------------------------------------------------------
-- Prose flow: wrap at the window edge, break on words, indent wrapped lines
-- so list items and blockquotes stay visually nested.
-- ---------------------------------------------------------------------------
set.wrap = true
set.linebreak = true -- break on word boundaries, not mid-word
set.breakindent = true -- wrapped lines keep the indent of the line they belong to
set.showbreak = '  ' -- small hanging indent on wrapped lines
set.textwidth = 0 -- no hard-wrapping while you type; wrap is visual only

-- Cursor stays vertically centered as you type -- "typewriter scrolling".
-- This is a native option, not a plugin: it's the single cheapest high-impact
-- line in this whole config.
set.scrolloff = 999

-- ---------------------------------------------------------------------------
-- Spelling: on by default for prose. Muted colors are set in
-- lua/plugins/colors.lua (default SpellBad red is much too loud for writing).
-- ---------------------------------------------------------------------------
set.spell = true
set.spelllang = 'en_us'
set.spellsuggest = 'best,9'

-- ---------------------------------------------------------------------------
-- Search / editing niceties
-- ---------------------------------------------------------------------------
set.ignorecase = true
set.smartcase = true
set.incsearch = true
set.hlsearch = true
set.inccommand = 'split'
set.undofile = true -- persistent undo across sessions -- you'll want this for articles
set.swapfile = false
set.backup = false
set.clipboard = 'unnamedplus'
set.mouse = 'a'
set.splitright = true
set.splitbelow = true
set.confirm = true -- ask instead of erroring on :q with unsaved changes

-- ---------------------------------------------------------------------------
-- Folding: available (useful for collapsing sections by heading), off by
-- default so opening a file doesn't greet you with a wall of closed folds.
-- ---------------------------------------------------------------------------
set.foldmethod = 'expr'
set.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
set.foldenable = false
set.foldlevel = 99

set.termguicolors = true

-- Snappier CursorHold (default 4000ms is sluggish for the citation-hover
-- preview in custom/bibtex_finder.lua to feel responsive).
set.updatetime = 500

-- ---------------------------------------------------------------------------
-- Word count for the statusline. vim.fn.wordcount() is native -- no plugin.
-- ---------------------------------------------------------------------------
function WriterStatusline()
  local wc = vim.fn.wordcount()
  local words = wc.visual_words or wc.words
  local name = vim.fn.expand '%:t'
  if name == '' then
    name = '[No Name]'
  end
  local modified = vim.bo.modified and ' [+]' or ''
  return string.format(' %s%s %%= %d words   %%l:%%c ', name, modified, words)
end
