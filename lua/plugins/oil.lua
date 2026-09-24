return {
  pack = {
    { src = 'https://github.com/stevearc/oil.nvim' },
  },

  config = function()
    require('oil').setup {
      default_file_explorer = true,
      columns = { 'icon' },
      view_options = { show_hidden = true },
      use_default_keymaps = true,
    }
  end,
}
