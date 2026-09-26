-- ============================================================================
-- Low-latency Typst preview in a browser tab, with cursor sync in both
-- directions -- move around in Neovim and the preview scrolls to match;
-- click in the preview and it jumps your cursor in Neovim. Talks to
-- tinymist's own preview machinery directly (incremental SVG frames over a
-- websocket data-plane), which is why this is the one place in this whole
-- config using a real plugin dependency instead of a hand-rolled module in
-- lua/custom/ -- that protocol genuinely isn't something to responsibly
-- reimplement from scratch, unlike everything else in here.
--
-- Dependency: `curl` (used to fetch its own helper binaries on first run).
-- `dependencies_bin` points it at the tinymist Mason already installs
-- (lua/plugins/typst.lua) instead of downloading a second copy.
-- `open_cmd` is set explicitly (the plugin's own default, nil, has unclear
-- fallback behavior) to force the system's URL opener.
--
-- ============================================================================
-- FORKED, NOT UPSTREAM: pack.src below points at
-- https://github.com/ArcticSnow/typst-preview.nvim instead of
-- chomosuke/typst-preview.nvim.
--
-- Reason: lua/typst-preview/server.lua hardcodes the `--partial-rendering`
-- CLI flag as a bare literal with no value and no reference to
-- config.opts.partial_rendering anywhere -- so nothing configurable in this
-- file could ever have controlled it (neither `partial_rendering` nor
-- `extra_args`, both tried first). tinymist 0.15.8's CLI parser requires an
-- explicit value and rejects the bare form:
--   error: a value is required for '--partial-rendering <ENABLE_PARTIAL_RENDERING>' but none was supplied
-- Confirmed by reading the plugin's actual source and by running its exact
-- spawned command by hand. The fork carries a one-line fix (inserting
-- `tostring(config.opts.partial_rendering)` after the flag).
--
-- A prior version of this file auto-patched the upstream plugin's installed
-- copy on every startup instead of forking -- replaced by this once a fixed
-- fork existed, since pointing at a fork with the real fix is more direct
-- than patching vendor code by string-matching on every launch.
--
-- If this gets merged upstream, point pack.src back at chomosuke's repo and
-- delete this whole comment block.
-- ============================================================================

return {
  pack = {
    -- Tracking `master` directly (not a semver tag range) -- you linked the
    -- master branch specifically, and semver-tag matching could otherwise
    -- resolve to an older, unfixed tag if the fix isn't cut as a release yet.
    { src = 'https://github.com/ArcticSnow/typst-preview.nvim', version = 'master' },
  },

  config = function()
    local opener = vim.fn.has 'mac' == 1 and 'open' or 'xdg-open'
    require('typst-preview').setup {
      dependencies_bin = { tinymist = 'tinymist' },
      open_cmd = opener .. ' %s',
      partial_rendering = true,
      debug=false,
    }
  end,
}
