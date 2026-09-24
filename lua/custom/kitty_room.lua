-- ============================================================================
-- Changes the ROOM, not just the page: when write mode turns on, bump Kitty's
-- font size up a notch via its remote-control protocol (the same mechanism
-- your main config's kitty_repl.lua already uses to drive a REPL pane) --
-- and back down when it turns off.
--
-- Confirmed-real command: `kitten @ set-font-size`. There's also a
-- `set-spacing` command for line-height/padding, but I couldn't pin down its
-- exact argument syntax confidently enough to ship it -- run
-- `kitten @ set-spacing -h` yourself and extend M.enable()/M.disable() below
-- if you want that too; the pattern is identical to the font-size call.
--
-- Silently does nothing outside Kitty (or if remote control isn't enabled)
-- rather than erroring -- this is meant to be a pure bonus, never something
-- that can break write mode if it fails.
-- ============================================================================

local M = {}

local DELTA = '+2' -- how many points to bump on enable (matched by -2 on disable)

local function in_kitty()
  return vim.env.TERM == 'xterm-kitty' or vim.env.KITTY_WINDOW_ID ~= nil
end

local function set_font_size(delta)
  if not in_kitty() then
    return
  end
  -- fire-and-forget; if remote control isn't enabled in kitty.conf
  -- (`allow_remote_control`) this just fails quietly
  vim.system({ 'kitten', '@', 'set-font-size', '--', delta }, { text = true })
end

function M.enable()
  set_font_size(DELTA)
end

function M.disable()
  set_font_size('-' .. DELTA:gsub('^%+', ''))
end

return M
