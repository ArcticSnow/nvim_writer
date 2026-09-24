-- Renders markdown inline as you read it (styled headings, bullets, bold/
-- italic, code blocks) while showing the raw source on whichever line your
-- cursor is on -- the same "reveal on focus" idea as paragraph_focus.lua,
-- just for syntax instead of prose. Uses mini.icons, already installed by
-- lua/plugins/mini.lua (loaded first -- see plugin_modules in
-- lua/config/pack.lua), so nothing extra to configure there.
--
-- Scoped to Markdown only (this plugin's own sensible default), matching
-- what was actually asked for -- add 'quarto' to file_types below if you
-- want it there too.

return {
  pack = {
    { src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim' },
  },

  config = function()
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    require('render-markdown').setup {
      file_types = { 'markdown' },
    }
  end,
}
