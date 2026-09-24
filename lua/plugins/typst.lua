-- ============================================================================
-- Typst support: tinymist (the actively-maintained Typst LSP; typst-lsp is
-- deprecated in its favor) via Mason, and Neovim's own NATIVE completion
-- (vim.lsp.completion, added in 0.11) instead of a completion-engine plugin
-- like blink.cmp/nvim-cmp.
--
-- LSP setup uses vim.lsp.config()/vim.lsp.enable() (native since 0.11), not
-- the older require('lspconfig').tinymist.setup{} -- that wrapper is
-- deprecated and due for removal in nvim-lspconfig v3.0.0 (:h
-- lspconfig-nvim-0.11). nvim-lspconfig is still a dependency: it's what
-- actually ships tinymist's cmd/filetypes/root_dir definition (as
-- lsp/tinymist.lua on 'runtimepath', which vim.lsp.enable() picks up
-- automatically) -- only the way we invoke it changed, not whether we need
-- it. vim.lsp.config() below layers our own `settings` on top of that.
--
-- `exportPdf = "onType"` keeps a compiled PDF on disk continuously as you
-- type -- also used by the manual PDF-viewer fallback in lua/config/keybinds.lua
-- (<leader>tv). Live preview itself now goes through tinymist's own preview
-- machinery via lua/plugins/typst_preview.lua, not this PDF file.
--
-- BUG FIX (earlier pass): mason-tool-installer.nvim's spec had the wrong
-- GitHub org (mason-org/mason-tool-installer.nvim -- that org holds
-- mason.nvim and mason-lspconfig.nvim, but mason-tool-installer.nvim was
-- never transferred there; it's still WhoIsSethDaniel/mason-tool-
-- installer.nvim). Since vim.pack.add() fails its ENTIRE call atomically on
-- one bad spec, this alone was enough to prevent every plugin in this
-- config from installing -- oil.nvim included, which is why it looked
-- "missing" even though it was (and still is) fully configured in
-- lua/plugins/oil.lua. pack.lua now also installs each plugin module
-- separately so this class of bug can't do that again.
-- ============================================================================

return {
  pack = {
    { src = 'https://github.com/neovim/nvim-lspconfig' },
    { src = 'https://github.com/mason-org/mason.nvim' },
    { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },
  },

  config = function()
    require('mason').setup {}
    require('mason-tool-installer').setup { ensure_installed = { 'tinymist' } }

    vim.diagnostic.config {
      severity_sort = true,
      float = { border = 'rounded', source = 'if_many' },
      underline = { severity = vim.diagnostic.severity.ERROR },
      virtual_text = { spacing = 2, source = 'if_many' }, -- toggled off while typing, see autocmds.lua
    }

    vim.lsp.config('tinymist', {
      settings = {
        formatterMode = 'typstyle',
        exportPdf = 'onType',
        semanticTokens = 'disable',
      },
    })
    vim.lsp.enable 'tinymist'

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('writer-lsp-attach', { clear = true }),
      callback = function(event)
        if vim.bo[event.buf].filetype ~= 'typst' then
          return
        end

        require('config.keybinds').lsp_attach(event)

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_completion, event.buf) then
          vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
        end
      end,
    })
  end,
}
