-- ============================================================================
-- The "room": toggles a centered writing column with chrome hidden, the way
-- goyo.vim does -- two empty, locked, fixed-width windows flanking the real
-- buffer so the text sits in the middle instead of running edge to edge.
-- Built from scratch (not goyo.vim itself) so it's small and does exactly
-- what this config needs: on enable, also turns on paragraph-focus dimming
-- and (if you're in Kitty) nudges the terminal's own font size up.
-- ============================================================================

local M = {}

local CONTENT_WIDTH = 84

local state = {
  active = false,
  left_win = nil,
  right_win = nil,
  origin_win = nil,
  saved = {},
}

local function make_pad(split_cmd, width)
  vim.cmd(split_cmd)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].cursorline = false
  vim.wo[win].winfixwidth = true
  vim.api.nvim_win_set_width(win, width)
  return win
end

function M.enable()
  if state.active then
    return
  end
  state.active = true
  state.origin_win = vim.api.nvim_get_current_win()

  -- Chrome
  state.saved.laststatus = vim.o.laststatus
  vim.o.laststatus = 0

  -- Make the window seams between the buffer and the pad windows invisible,
  -- and hide the end-of-buffer "~" tildes -- otherwise the centering trick
  -- looks like "three windows" instead of "a page".
  state.saved.fillchars = vim.o.fillchars
  vim.opt.fillchars:append { vert = ' ', eob = ' ' }
  state.saved.winseparator_hl = vim.api.nvim_get_hl(0, { name = 'WinSeparator', link = false })
  local normal_bg = vim.api.nvim_get_hl(0, { name = 'Normal', link = false }).bg
  vim.api.nvim_set_hl(0, 'WinSeparator', { fg = normal_bg, bg = normal_bg })

  -- The column itself
  local total_cols = vim.o.columns
  local pad = math.floor((total_cols - CONTENT_WIDTH) / 2)
  if pad > 2 then
    make_pad('topleft vsplit', pad)
    state.left_win = vim.api.nvim_get_current_win()

    vim.api.nvim_set_current_win(state.origin_win)
    make_pad('botright vsplit', pad)
    state.right_win = vim.api.nvim_get_current_win()

    vim.api.nvim_set_current_win(state.origin_win)
  end

  -- The sentence
  pcall(function()
    require('custom.paragraph_focus').enable()
  end)

  -- The room
  pcall(function()
    require('custom.kitty_room').enable()
  end)
end

function M.disable()
  if not state.active then
    return
  end
  state.active = false

  if state.left_win and vim.api.nvim_win_is_valid(state.left_win) then
    vim.api.nvim_win_close(state.left_win, true)
  end
  if state.right_win and vim.api.nvim_win_is_valid(state.right_win) then
    vim.api.nvim_win_close(state.right_win, true)
  end
  state.left_win, state.right_win = nil, nil

  vim.o.laststatus = state.saved.laststatus or 2
  if state.saved.fillchars then
    vim.o.fillchars = state.saved.fillchars
  end
  if state.saved.winseparator_hl then
    vim.api.nvim_set_hl(0, 'WinSeparator', state.saved.winseparator_hl)
  end

  pcall(function()
    require('custom.paragraph_focus').disable()
  end)
  pcall(function()
    require('custom.kitty_room').disable()
  end)

  if state.origin_win and vim.api.nvim_win_is_valid(state.origin_win) then
    vim.api.nvim_set_current_win(state.origin_win)
  end
end

function M.toggle()
  if state.active then
    M.disable()
  else
    M.enable()
  end
end

function M.toggle_background()
  vim.o.background = (vim.o.background == 'dark') and 'light' or 'dark'
end

return M
