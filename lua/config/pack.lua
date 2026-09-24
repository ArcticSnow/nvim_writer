-- ============================================================================
-- Plugin manager: native vim.pack (Neovim 0.12+). Same pattern as your main
-- config's lua/config/pack.lua -- see that file's header comment for the full
-- explanation of the pack/config contract. Short version:
--
--   Every lua/plugins/*.lua file returns { pack = <spec(s)>, config = <fn> }.
--
-- UNLIKE the main config, this installs and configures each module's plugins
-- SEPARATELY (one vim.pack.add() call per module, not one giant combined
-- call), each wrapped in pcall. vim.pack.add() fails atomically -- a single
-- bad spec (wrong URL, network hiccup, private repo) throws and aborts the
-- ENTIRE call, including every plugin listed before or after the bad one in
-- that array. With everything batched into one call, that meant one wrong
-- git URL for mason-tool-installer.nvim was enough to prevent oil.nvim,
-- Telescope, mini.nvim -- everything -- from ever installing, even though
-- their own specs were perfectly fine. Per-module calls mean a failure in
-- one module (reported via vim.notify, not silently swallowed) can't take
-- down any other module.
-- ============================================================================

-- No PackChanged build hooks needed currently -- telescope-fzf-native.nvim
-- (the one plugin here that needed one, via `make`) was removed since it
-- needs a C compiler that isn't available. Add one back here the same way
-- if a future plugin needs a post-install/update step:
--   vim.api.nvim_create_autocmd('PackChanged', {
--     callback = function(ev)
--       if ev.data.spec.name == 'some-plugin' and (ev.data.kind == 'install' or ev.data.kind == 'update') then
--         vim.system({ 'some-build-command' }, { cwd = ev.data.path })
--       end
--     end,
--   })

local plugin_modules = {
  'colors',
  'treesitter',
  'typst',
  'typst_preview',
  'telescope',
  'mini',
  'markdown_render',
  'oil',
  'auto-session',
  'misc',
  'obsidian',
}

for _, name in ipairs(plugin_modules) do
  local ok, err = pcall(function()
    local mod = require('plugins.' .. name)
    local pack = mod.pack
    if pack then
      local specs = pack.src and { pack } or pack
      -- load = true: reproduce "everything loads at startup" (see the main
      -- config's pack.lua for why vim.pack's own default of load=false
      -- during init.lua sourcing is a trap).
      vim.pack.add(specs, { load = true })
    end
    if mod.config then
      mod.config()
    end
  end)

  if not ok then
    vim.schedule(function()
      vim.notify(
        string.format('nvim_writer: plugin module "%s" failed to load:\n%s', name, err),
        vim.log.levels.ERROR,
        { title = 'pack.lua' }
      )
    end)
  end
end
