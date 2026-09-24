return {
  pack = {
    { src = 'https://github.com/folke/which-key.nvim' },
    { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  },

  config = function()
    require('which-key').setup {}
    require('gitsigns').setup {
      signs = {
        add = { text = '│' },
        change = { text = '│' },
        delete = { text = '_' },
      },
    }
  end,
}
