-- Carried over from your main config since you mentioned relying on it for
-- tag tracking. Point `path` at whichever vault your articles' notes/tags
-- actually live in -- delete this file (and remove 'obsidian' from
-- lua/config/pack.lua's plugin_modules list) if you'd rather keep this config
-- writing-only and untangled from your notes vault.

return {
  pack = {
    { src = 'https://github.com/obsidian-nvim/obsidian.nvim', version = vim.version.range '*' },
  },

  config = function()
    ---@module 'obsidian'
    ---@type obsidian.config
    require('obsidian').setup {
      legacy_commands = false,
      workspaces = {
        {
          name = 'work',
          path = '/home/filhols/Documents/MF_vault/',
        },
      },
    }
  end,
}
