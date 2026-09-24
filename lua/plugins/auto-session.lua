return {
  pack = {
    { src = 'https://github.com/rmagatti/auto-session' },
  },

  config = function()
    ---@module "auto-session"
    ---@type AutoSession.Config
    require('auto-session').setup {
      suppressed_dirs = { '~/', '/' },
      cwd_change_handling = false,
    }
  end,
}
