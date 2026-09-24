-- ============================================================================
-- Autocmds
-- ============================================================================

-- Belt-and-suspenders filetype detection for Typst (some Neovim builds
-- already know *.typ; this makes sure regardless).
vim.filetype.add {
  extension = {
    typ = 'typst',
  },
}

-- Quiet diagnostics while you're mid-sentence: no virtual text flicker as you
-- type, restored the moment you leave insert mode. LSP diagnostics are useful
-- for Typst (a compile error IS worth knowing about immediately), just not
-- while your cursor is mid-word.
local diagnostics_group = vim.api.nvim_create_augroup('writer-quiet-diagnostics', { clear = true })

vim.api.nvim_create_autocmd('InsertEnter', {
  group = diagnostics_group,
  callback = function()
    vim.diagnostic.config { virtual_text = false }
  end,
})

vim.api.nvim_create_autocmd('InsertLeave', {
  group = diagnostics_group,
  callback = function()
    vim.diagnostic.config { virtual_text = { spacing = 2, source = 'if_many' } }
  end,
})

-- bibtex_finder's citation_format differs by filetype: Markdown wants
-- "[@key]", Typst wants a bare "@key" (referencing #bibliography(...)).
-- Switched automatically so you never have to think about it. Also attaches
-- the CursorHold citation-preview (see custom/bibtex_finder.lua) here, since
-- both are "things this buffer needs for citations to feel good."
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'quarto' },
  callback = function()
    local bibtex_finder = require 'custom.bibtex_finder'
    bibtex_finder.config.citation_format = '[@%s]'
    bibtex_finder.attach_cursor_preview()
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'typst',
  callback = function()
    local bibtex_finder = require 'custom.bibtex_finder'
    bibtex_finder.config.citation_format = '@%s'
    bibtex_finder.attach_cursor_preview()
  end,
})

-- Reasonable defaults for prose filetypes specifically (in case you ever open
-- something else in this config -- a README, a commit message, notes.txt).
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'quarto', 'typst', 'text', 'gitcommit' },
  callback = function()
    vim.opt_local.spell = true
  end,
})
