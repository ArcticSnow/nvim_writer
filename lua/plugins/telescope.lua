return {
  pack = {
    { src = 'https://github.com/nvim-telescope/telescope.nvim', version = '0.1.8' },
    { src = 'https://github.com/nvim-lua/plenary.nvim' },
    { src = 'https://github.com/nvim-telescope/telescope-fzf-native.nvim' },
  },

  config = function()
    require('telescope').setup {
      pickers = {
        find_files = { theme = 'ivy' },
        live_grep = { theme = 'ivy' },
        buffers = { theme = 'ivy' },
      },
    }
    require('telescope').load_extension 'fzf'
  end,
}
