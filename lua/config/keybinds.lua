-- ============================================================================
-- All keymaps, in one file (same convention as your main config). Loads
-- before lua/config/pack.lua installs plugins, so anything that touches a
-- plugin's Lua API directly is wrapped in a closure -- see the Telescope
-- section. Returns a small table at the bottom so lua/plugins/typst.lua can
-- call back into lsp_attach() from its LspAttach autocmd.
-- ============================================================================

local map = vim.keymap.set

-- ---------------------------------------------------------------------------
-- Citations (custom.bibtex_finder -- ported from your main config, with a
-- filetype-aware citation format added; see lua/config/autocmds.lua)
-- ---------------------------------------------------------------------------
map('n', '<leader>bb', function()
  require('custom.bibtex_finder').search_and_insert()
end, { desc = 'Insert citation' })

map('n', '<leader>bz', function()
  require('custom.bibtex_finder').select_bib_file()
end, { desc = 'Select BibTeX file' })

map('n', '<leader>bp', function()
  require('custom.bibtex_finder').preview_at_cursor()
end, { desc = 'Preview citation under cursor' })

-- ---------------------------------------------------------------------------
-- The room, the sentence, the type -- see lua/custom/*.lua for each.
-- ---------------------------------------------------------------------------
map('n', '<leader>zz', function()
  require('custom.prose_mode').toggle()
end, { desc = 'Toggle write mode (room + focus)' })

map('n', '<leader>zf', function()
  require('custom.paragraph_focus').toggle()
end, { desc = 'Toggle paragraph-focus dimming' })

map('n', '<leader>zt', function()
  require('custom.smart_typography').toggle()
end, { desc = 'Toggle typographic autocorrect' })

map('n', '<leader>zb', function()
  require('custom.prose_mode').toggle_background()
end, { desc = 'Toggle light/dark background' })

-- ---------------------------------------------------------------------------
-- Outline: toggleable side panel (not a picker) -- see lua/custom/outline_panel.lua
-- ---------------------------------------------------------------------------
map('n', '<leader>to', function()
  require('custom.outline_panel').toggle()
end, { desc = 'Toggle outline panel' })

-- ---------------------------------------------------------------------------
-- Finding things (Telescope) -- require()s deferred to the callback since
-- this file loads before pack.lua installs Telescope.
-- ---------------------------------------------------------------------------
map('n', '<leader>ff', function()
  require('telescope.builtin').find_files()
end, { desc = 'Find files' })

map('n', '<leader>fg', function()
  require('telescope.builtin').live_grep()
end, { desc = 'Live grep' })

map('n', '<leader>fb', function()
  require('telescope.builtin').buffers()
end, { desc = 'Find buffers' })

-- ---------------------------------------------------------------------------
-- Files (oil.nvim -- takes over the buffer instead of a permanent sidebar,
-- which is the point: no tree pane sitting in view while you write)
-- ---------------------------------------------------------------------------
map('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
map('n', '+', '<CMD>Oil --float<CR>', { desc = 'Open parent directory (floating)' })

-- ---------------------------------------------------------------------------
-- Editing conveniences
-- ---------------------------------------------------------------------------
map('v', '<', '<gv', { desc = 'Indent and reselect' })
map('v', '>', '>gv', { desc = 'Indent and reselect' })
map('n', ']]', '<cmd>cnext<CR>', { desc = 'Next quickfix item' })
map('n', '[[', '<cmd>cprev<CR>', { desc = 'Previous quickfix item' })
map('n', '<c-h>', '<c-w>h', { desc = 'Move to left window' })
map('n', '<c-j>', '<c-w>j', { desc = 'Move to bottom window' })
map('n', '<c-k>', '<c-w>k', { desc = 'Move to top window' })
map('n', '<c-l>', '<c-w>l', { desc = 'Move to right window' })

-- ---------------------------------------------------------------------------
-- Typst compile/preview -- lua/custom/typst_preview.lua
-- ---------------------------------------------------------------------------
map('n', '<leader>tp', function()
  require('custom.typst_preview').toggle()
end, { desc = 'Toggle Typst live preview (Kitty)' })

map('n', ']p', function()
  require('custom.typst_preview').next_page()
end, { desc = 'Typst preview: next page' })

map('n', '[p', function()
  require('custom.typst_preview').prev_page()
end, { desc = 'Typst preview: previous page' })

map('n', '<leader>tv', function()
  local pdf = (vim.api.nvim_buf_get_name(0):gsub('%.typ$', '')) .. '.pdf'
  if vim.fn.filereadable(pdf) == 0 then
    vim.notify('No compiled PDF yet: ' .. pdf, vim.log.levels.WARN)
    return
  end
  local opener = vim.fn.has 'mac' == 1 and 'open' or 'xdg-open'
  vim.system({ opener, pdf })
end, { desc = 'Open compiled PDF in system viewer' })

map('n', '<leader>tc', function()
  if vim.fn.executable 'typst' == 0 then
    vim.notify('`typst` CLI not found (tinymist compiles internally via exportPdf -- this is only a manual fallback)', vim.log.levels.WARN)
    return
  end
  local file = vim.api.nvim_buf_get_name(0)
  vim.system(
    { 'typst', 'compile', file },
    {},
    vim.schedule_wrap(function(res)
      if res.code == 0 then
        vim.notify('Typst compiled', vim.log.levels.INFO)
      else
        vim.notify('Typst compile failed:\n' .. (res.stderr or ''), vim.log.levels.ERROR)
      end
    end)
  )
end, { desc = 'Force-compile Typst document (manual fallback)' })

-- ---------------------------------------------------------------------------
-- LSP (Typst, via tinymist) -- exposed as lsp_attach() below since it's
-- called from lua/plugins/typst.lua's LspAttach autocmd, not at load time.
-- ---------------------------------------------------------------------------
local function lsp_attach(event)
  local lmap = function(keys, func, desc, mode)
    mode = mode or 'n'
    vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
  end

  lmap('grn', vim.lsp.buf.rename, '[R]e[n]ame')
  lmap('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
  lmap('grd', vim.lsp.buf.definition, '[G]oto [D]efinition')
  lmap('grr', function()
    require('telescope.builtin').lsp_references()
  end, '[G]oto [R]eferences')
  lmap('gO', function()
    require('telescope.builtin').lsp_document_symbols()
  end, 'Document symbols')
  lmap('K', vim.lsp.buf.hover, 'Hover')
end

return {
  lsp_attach = lsp_attach,
}
