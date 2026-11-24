-- ============================================================================
-- Per-buffer writing language: English by default, French when a document
-- says so. Switches two things together:
--   - native spell checking ('spelllang': en_us <-> fr)
--   - the grammar checker's language (lua/custom/grammar.lua, LTeX+), which
--     re-checks right away if it's running for this buffer
--
-- Why not just `spelllang = 'en_us,fr'` globally? With both dictionaries
-- active, an English typo that happens to be a valid French word passes
-- silently. Switching per buffer avoids that.
--
-- Auto-detected when a buffer opens (and again on save, unless you've
-- toggled by hand): a Typst `lang: "fr"` anywhere in the first lines (e.g.
-- `#set text(lang: "fr")`, as in the CNRS CR template), or a Markdown/Quarto
-- front-matter `lang: fr`. Anything else is English. Toggle manually with
-- <leader>gl.
--
-- First French use: Neovim will offer to download the French spell file
-- (needs network once).
-- ============================================================================

local M = {}

local SCAN_LINES = 40

local SPELLLANG = { en = 'en_us', fr = 'fr' }

--- Pure function (no Neovim calls, so it's testable on its own): given the
--- first lines of a document, return 'fr' or 'en'.
function M.detect_lines(lines)
  for _, line in ipairs(lines) do
    local code = line:match 'lang:%s*"(%a%a)"' or line:match '^lang:%s*["\']?(%a%a)'
    if code then
      return code:lower() == 'fr' and 'fr' or 'en'
    end
  end
  return 'en'
end

--- Apply the buffer's current language to spell checking and, if it's
--- running for this buffer, to the grammar checker.
function M.apply(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.bo[bufnr].spelllang = SPELLLANG[vim.b[bufnr].writer_lang or 'en'] or SPELLLANG.en

  local ok, grammar = pcall(require, 'custom.grammar')
  if ok then
    grammar.language_changed(bufnr)
  end
end

function M.toggle()
  local bufnr = vim.api.nvim_get_current_buf()
  local new = (vim.b[bufnr].writer_lang or 'en') == 'en' and 'fr' or 'en'
  vim.b[bufnr].writer_lang = new
  vim.b[bufnr].writer_lang_manual = true -- stop save-time auto-detect from undoing this
  M.apply(bufnr)
  vim.notify('Writing language: ' .. new, vim.log.levels.INFO)
end

local PROSE_FILETYPES = { markdown = true, quarto = true, typst = true }

function M.setup()
  local group = vim.api.nvim_create_augroup('writer-language', { clear = true })

  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = { 'markdown', 'quarto', 'typst' },
    callback = function(args)
      vim.b[args.buf].writer_lang = M.detect_lines(vim.api.nvim_buf_get_lines(args.buf, 0, SCAN_LINES, false))
      M.apply(args.buf)
    end,
  })

  -- Re-detect on save, so inserting a template that declares lang: "fr" into
  -- an empty buffer picks it up -- unless you've toggled by hand.
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    callback = function(args)
      if not PROSE_FILETYPES[vim.bo[args.buf].filetype] or vim.b[args.buf].writer_lang_manual then
        return
      end
      local detected = M.detect_lines(vim.api.nvim_buf_get_lines(args.buf, 0, SCAN_LINES, false))
      if detected ~= vim.b[args.buf].writer_lang then
        vim.b[args.buf].writer_lang = detected
        M.apply(args.buf)
      end
    end,
  })
end

return M
