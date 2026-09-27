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
    { src = 'https://github.com/zaldih/themery.nvim' },
    { src = 'https://github.com/ellisonleao/gruvbox.nvim' },
    { src = 'https://github.com/rose-pine/neovim', name = 'rose-pine' },
    { src = 'https://github.com/rebelot/kanagawa.nvim' },
  },

  config = function()
    require('everforest').setup { background = 'soft' }
    require('gruvbox').setup {}
    require('kanagawa').setup {
      background = { dark = 'wave', light = 'lotus' },
    }
    -- rose-pine needs no setup() call for defaults

    require('themery').setup {
      themes = {
        { name = 'Everforest Dark', colorscheme = 'everforest', before = [[ vim.opt.background = "dark" ]] },
        { name = 'Everforest Light', colorscheme = 'everforest', before = [[ vim.opt.background = "light" ]] },
        { name = 'Gruvbox Dark', colorscheme = 'gruvbox', before = [[ vim.opt.background = "dark" ]] },
        { name = 'Gruvbox Light', colorscheme = 'gruvbox', before = [[ vim.opt.background = "light" ]] },
        { name = 'Rose Pine', colorscheme = 'rose-pine' },
        { name = 'Rose Pine Dawn', colorscheme = 'rose-pine-dawn' },
        { name = 'Kanagawa Wave', colorscheme = 'kanagawa', before = [[ vim.opt.background = "dark" ]] },
        { name = 'Kanagawa Lotus', colorscheme = 'kanagawa', before = [[ vim.opt.background = "light" ]] },
      },
    }

    vim.o.background = 'dark'
    vim.cmd.colorscheme 'everforest'

    -- Tuned for Everforest specifically -- see caveat above.
    vim.api.nvim_set_hl(0, 'SpellBad', { undercurl = true, sp = '#e67e80', bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'SpellCap', { undercurl = true, sp = '#7fbbb3', bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'SpellRare', { undercurl = true, sp = '#d699b6', bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'SpellLocal', { undercurl = true, sp = '#83c092', bg = 'NONE' })
  end,
}
