-- telescope-fzf-native.nvim removed: despite the name, it doesn't need the
-- `fzf` binary at all (it's a self-contained C matcher replicating fzf's
-- algorithm, not a wrapper around the CLI tool) -- but it does need a C
-- compiler to `make` it locally, which is the more likely thing actually
-- missing. Telescope's own default sorter (pure Lua) works fine without it;
-- the difference is only noticeable on genuinely large result sets, which a
-- personal writing folder isn't.

return {
  pack = {
    { src = 'https://github.com/nvim-telescope/telescope.nvim', version = '0.1.8' },
    { src = 'https://github.com/nvim-lua/plenary.nvim' },
  },

  config = function()
    require('telescope').setup {
      pickers = {
        find_files = { theme = 'ivy' },
        live_grep = { theme = 'ivy' },
        buffers = { theme = 'ivy' },
      },
    }
  end,
}
