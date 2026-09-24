-- ============================================================================
-- nvim-treesitter, `main` branch -- same rewrite/API your main config uses.
-- See that config's lua/plugins/treesitter.lua for the general explanation.
--
-- TYPST: registers uben0/tree-sitter-typst manually, since Typst has no
-- parser bundled in nvim-treesitter's own catalog. Picked over the
-- alternative I shipped last time (frozolotl/tree-sitter-typst) because it's
-- more complete (markup/code/math modes, indentation and folding all done --
-- frozolotl's still has code mode, lists, enums and terms unimplemented) and
-- more established (189 stars/239 commits vs. 77/83).
--
-- IMPORTANT DETAIL THAT WAS MISSING LAST TIME: registering a custom parser
-- only gets you the COMPILED GRAMMAR. Neovim also needs QUERY FILES
-- (queries/typst/highlights.scm, injections.scm) to actually highlight
-- anything with it, and nvim-treesitter does not fetch those for unlisted
-- parsers -- every third-party guide for adding Typst to Neovim has a manual
-- "copy queries/ into your config's queries/typst/" step. ensure_typst_queries()
-- below automates exactly that: a background, self-healing git clone (retries
-- on next startup if it fails) that copies just the query files out of the
-- same grammar repo into this config's own queries/typst/ directory, which
-- Neovim picks up automatically since it's on 'runtimepath'.
-- ============================================================================

local ensure_installed = { 'markdown', 'markdown_inline', 'yaml', 'bibtex' }

local TYPST_GRAMMAR_URL = 'https://github.com/uben0/tree-sitter-typst'

--- Fetch queries/typst/*.scm from the grammar repo into this config's own
--- queries/typst/ directory, if we don't already have them. Fire-and-forget,
--- async, safe to call every startup (near-instant no-op once it's succeeded
--- once).
local function ensure_typst_queries()
  local target_dir = vim.fn.stdpath 'config' .. '/queries/typst'
  if vim.uv.fs_stat(target_dir .. '/highlights.scm') then
    return -- already have them
  end

  local tmp = vim.fn.tempname()
  vim.system({ 'git', 'clone', '--depth', '1', TYPST_GRAMMAR_URL, tmp }, { text = true }, function(res)
    if res.code ~= 0 then
      vim.schedule(function()
        vim.notify(
          'Typst: could not fetch highlight queries (will retry next startup):\n' .. (res.stderr or ''),
          vim.log.levels.WARN,
          { title = 'treesitter' }
        )
      end)
      return
    end

    vim.fn.mkdir(target_dir, 'p')
    local src_dir = tmp .. '/queries/typst'
    local copied = {}
    for _, fname in ipairs { 'highlights.scm', 'injections.scm', 'indents.scm', 'folds.scm', 'locals.scm' } do
      local src = src_dir .. '/' .. fname
      if vim.uv.fs_stat(src) then
        vim.uv.fs_copyfile(src, target_dir .. '/' .. fname)
        table.insert(copied, fname)
      end
    end
    vim.fn.delete(tmp, 'rf')

    vim.schedule(function()
      if #copied > 0 then
        vim.notify('Typst: installed queries (' .. table.concat(copied, ', ') .. ')', vim.log.levels.INFO, { title = 'treesitter' })
      else
        vim.notify('Typst: grammar repo had no queries/typst/ directory -- highlighting may be limited', vim.log.levels.WARN, { title = 'treesitter' })
      end
    end)
  end)
end

return {
  pack = {
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  },

  config = function()
    -- Register the Typst parser (documented way to add an unlisted one on
    -- the `main` branch). No `branch =` field: let it track whatever the
    -- repo's default branch is rather than hard-coding one.
    vim.api.nvim_create_autocmd('User', {
      pattern = 'TSUpdate',
      callback = function()
        require('nvim-treesitter.parsers').typst = {
          install_info = { url = TYPST_GRAMMAR_URL },
        }
      end,
    })

    ensure_typst_queries()

    -- Batch-install what we always want, up front.
    local already_installed = require('nvim-treesitter.config').get_installed()
    local to_install = vim
      .iter(ensure_installed)
      :filter(function(lang)
        return not vim.tbl_contains(already_installed, lang)
      end)
      :totable()
    if #to_install > 0 then
      require('nvim-treesitter').install(to_install)
    end
    if not vim.tbl_contains(already_installed, 'typst') then
      pcall(require('nvim-treesitter').install, { 'typst' })
    end

    -- Highlighting + indent, installing on demand for anything not in the
    -- list above.
    vim.api.nvim_create_autocmd('FileType', {
      callback = function(args)
        local lang = vim.treesitter.language.get_lang(args.match) or args.match
        if not lang or lang == '' then
          return
        end

        local function enable()
          pcall(vim.treesitter.start, args.buf)
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end

        if vim.treesitter.language.add(lang) then
          enable()
        else
          local ok, job = pcall(require('nvim-treesitter').install, { lang })
          if ok and job and job.await then
            job:await(enable)
          end
        end
      end,
    })
  end,
}
