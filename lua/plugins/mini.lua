-- Deliberately a small subset, not the whole mini.nvim catalog: just the
-- editing conveniences that actually help writing prose (auto-closing quotes/
-- brackets, wrapping a selection in *emphasis*/`code`/quotes, better text
-- objects), plus mini.icons since oil.lua needs it.

return {
  pack = {
    { src = 'https://github.com/echasnovski/mini.pairs' },
    { src = 'https://github.com/echasnovski/mini.surround' },
    { src = 'https://github.com/echasnovski/mini.ai' },
    { src = 'https://github.com/echasnovski/mini.icons' },
  },

  config = function()
    require('mini.pairs').setup {}
    require('mini.surround').setup {}
    require('mini.ai').setup {
      custom_textobjects = {
        -- Typst code cell object -- ```typst ... ``` and raw-typst blocks
        x = { '```%S+%s()[^`]+()```' },
      },
    }
    require('mini.icons').setup {}
  end,
}
