-- ============================================================================
-- Base theme: Everforest, soft contrast. Warm, muted, sober -- a good paper-
-- like starting point without needing a bespoke colorscheme. The "paper"
-- effect (extra warmth, dimmed chrome) is layered on top by
-- lua/custom/prose_mode.lua when you toggle write mode; this file just sets
-- a calm baseline that's already pleasant with write mode OFF.
-- ============================================================================

return {
  pack = {
    { src = 'https://github.com/neanias/everforest-nvim' },
  },

  config = function()
    require('everforest').setup {
      background = 'soft',
      italics = true,
      -- disable the busier bits by default; write mode turns even more of
      -- this down further
      disable_italic_comments = false,
    }
    vim.o.background = 'dark'
    vim.cmd.colorscheme 'everforest'

    -- Default spellcheck colors (bright red squiggly underline, etc.) are
    -- built for spotting bugs, not for a page of prose you're going to keep
    -- looking at for an hour. Soften them to a quiet undercurl.
    vim.api.nvim_set_hl(0, 'SpellBad', { undercurl = true, sp = '#e67e80', bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'SpellCap', { undercurl = true, sp = '#7fbbb3', bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'SpellRare', { undercurl = true, sp = '#d699b6', bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'SpellLocal', { undercurl = true, sp = '#83c092', bg = 'NONE' })
  end,
}
