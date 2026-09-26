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
--
-- html/latex explicitly disabled below: their treesitter parsers were never
-- requested (not in lua/plugins/treesitter.lua's ensure_installed), and
-- leaving them on just produces two permanent "parser not installed"
-- warnings in :checkhealth for a feature nobody asked for. Re-enable if you
-- ever want LaTeX math or embedded HTML rendered inline, and add 'html'/
-- 'latex' to that ensure_installed list to match.

return {
  pack = {
    { src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim' },
  },

  config = function()
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    require('render-markdown').setup {
      file_types = { 'markdown' },
      html = { enabled = false },
      latex = { enabled = false },
    }
  end,
}
