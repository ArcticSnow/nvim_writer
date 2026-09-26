-- Carried over from your main config since you mentioned relying on it for
-- tag tracking. Point `path` at whichever vault your articles' notes/tags
-- actually live in -- delete this file (and remove 'obsidian' from
-- lua/config/pack.lua's plugin_modules list) if you'd rather keep this config
-- writing-only and untangled from your notes vault.
--
-- FOUND VIA :checkhealth: obsidian.nvim's own UI module (checkbox/heading/
-- etc. rendering) conflicts with lua/plugins/markdown_render.lua's
-- render-markdown.nvim -- both try to render the same elements, and
-- render-markdown's healthcheck flags this as a hard error, not just a
-- warning. `ui = { enable = false }` below turns obsidian's own rendering
-- off so render-markdown.nvim is the single renderer -- you still get all
-- of obsidian's non-visual features (tags, links, workspaces, etc.).

return {
  pack = {
    { src = 'https://github.com/obsidian-nvim/obsidian.nvim', version = vim.version.range '*' },
  },

  config = function()
    ---@module 'obsidian'
    ---@type obsidian.config
    require('obsidian').setup {
      legacy_commands = false,
      ui = { enable = false },
      workspaces = {
        {
          name = 'work',
          path = '/home/filhols/Documents/MF_vault/',
        },
      },
    }
  end,
}
