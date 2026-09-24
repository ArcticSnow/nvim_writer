-- ============================================================================
-- nvim-treesitter, `main` branch -- same rewrite/API your main config uses.
-- See that config's lua/plugins/treesitter.lua for the general explanation.
--
-- TYPST -- what changed and why this file got much simpler: there's now a
-- dedicated community org, neovim-treesitter (https://github.com/neovim-
-- treesitter), that maintains an editor-agnostic parser+queries registry
-- specifically to solve the exact problem I was hand-rolling a workaround
-- for. Its registry lists 'typst' as a normal entry: parser
-- uben0/tree-sitter-typst (confirms the grammar I'd already picked), queries
-- at the dedicated neovim-treesitter/nvim-treesitter-queries-typst repo.
-- A nvim-treesitter checkout that consumes this registry (recent `main`
-- branch should) installs both automatically from a plain `:TSInstall typst`
-- -- no manual `install_info` registration, no fetching query files by hand.
--
-- That hand-rolled query-fetching code is exactly what crashed on you: its
-- success path called `vim.fn.mkdir()` directly from inside an unscheduled
-- async git-clone callback (E5560: Vimscript functions can't be called from
-- a "fast event" context -- needs `vim.schedule()`, which I'd only wrapped
-- around the error path, not the success path). Worse, because that bug
-- fired asynchronously and unpredictably -- sometime after this module's
-- config() had already returned, while OTHER modules' installs were still
-- in flight -- the uncaught error could land in the middle of any of them,
-- which is why oil/telescope/mini/auto-session/misc/obsidian all reported
-- "failed to load" too, not just typst. Removing the source of that stray
-- async callback fixes both problems at once, not just the crash.
--
-- If `:TSInstall typst` doesn't work for you, that means your nvim-
-- treesitter checkout predates this registry integration. Check
-- https://github.com/neovim-treesitter/treesitter-parser-registry for the
-- current recommended manual-registration approach at that point -- I've
-- gotten the hand-rolled version of this wrong twice now and don't want to
-- ship a third guess.
-- ============================================================================

local ensure_installed = { 'markdown', 'markdown_inline', 'yaml', 'bibtex', 'typst' }

return {
  pack = {
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  },

  config = function()
    local already_installed = require('nvim-treesitter.config').get_installed()
    local to_install = vim
      .iter(ensure_installed)
      :filter(function(lang)
        return not vim.tbl_contains(already_installed, lang)
      end)
      :totable()

    -- Installed one language at a time, each in its own pcall: if 'typst'
    -- specifically turns out not to be installable (see note above), that
    -- shouldn't stop markdown/yaml/bibtex from installing.
    for _, lang in ipairs(to_install) do
      local ok, err = pcall(require('nvim-treesitter').install, { lang })
      if not ok then
        vim.schedule(function()
          vim.notify('treesitter: could not install "' .. lang .. '":\n' .. tostring(err), vim.log.levels.WARN, { title = 'treesitter' })
        end)
      end
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
