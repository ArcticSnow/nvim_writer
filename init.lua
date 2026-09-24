-- ============================================================================
-- nvim_writer -- an independent Neovim config for long-form writing:
-- Markdown + Typst articles, backed by BibTeX references.
--
-- This is a SEPARATE config from your main one. Run it side by side with:
--
--     NVIM_APPNAME=nvim_writer nvim
--
-- (put this whole folder at ~/.config/nvim_writer -- Neovim looks for
-- NVIM_APPNAME under XDG_CONFIG_HOME the same way it looks for "nvim")
--
-- Philosophy: sober, minimalist, practical. Small personally-tuned modules
-- (lua/custom/) over large multi-purpose plugins wherever that's reasonable.
-- See README.md for the design reasoning behind each piece and a full
-- keymap reference.
--
-- Requires Neovim 0.12+ (vim.pack, native vim.lsp.completion).
-- ============================================================================

require('config.options')
require('config.keybinds')
require('config.pack')
require('config.autocmds')
