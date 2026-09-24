-- ============================================================================
-- Low-latency Typst preview in a browser tab, with cursor sync in both
-- directions -- move around in Neovim and the preview scrolls to match;
-- click in the preview and it jumps your cursor in Neovim. Talks to
-- tinymist's own preview machinery directly (incremental SVG frames over a
-- websocket data-plane), which is why this is the one place in this whole
-- config using a real plugin dependency instead of a hand-rolled module in
-- lua/custom/ -- that protocol (task IDs, tinymist's own known config-reload
-- race, SVG frame diffing) genuinely isn't something to responsibly
-- reimplement from scratch, unlike everything else in here.
--
-- Replaces the earlier Kitty-window rasterize-and-swap approach (was
-- lua/custom/typst_preview.lua, now removed). This one is smoother --
-- true incremental rendering, no window-recreation flicker -- and adds
-- cursor sync, at the cost of a browser tab instead of a terminal-native
-- window. `<leader>tp` still toggles it; the page-navigation keymaps
-- (`]p`/`[p`) from the old version are gone since this is a continuously
-- scrollable view, not page-by-page.
--
-- Dependency: `curl` (used to fetch its own helper binaries on first run --
-- almost certainly already on your system). `dependencies_bin` below points
-- it at the tinymist Mason already installs (lua/plugins/typst.lua) instead
-- of downloading a second, potentially version-mismatched copy.
-- ============================================================================

return {
  pack = {
    { src = 'https://github.com/chomosuke/typst-preview.nvim', version = vim.version.range '1.0' },
  },

  config = function()
    require('typst-preview').setup {
      dependencies_bin = { tinymist = 'tinymist' },
    }
  end,
}
