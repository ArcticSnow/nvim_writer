-- ============================================================================
-- Grammar checking (LTeX+, on demand) and per-buffer writing language.
-- See lua/custom/grammar.lua and lua/custom/writing_language.lua.
--
-- No `pack` entries: LTeX+ is a language server, not a plugin. Mason installs
-- it (ensure_installed in lua/plugins/typst.lua), which is why this module
-- must load after 'typst' in lua/config/pack.lua.
-- ============================================================================

return {
  config = function()
    require('custom.grammar').setup()
    require('custom.writing_language').setup()
  end,
}
