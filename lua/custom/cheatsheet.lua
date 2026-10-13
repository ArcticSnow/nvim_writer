-- ============================================================================
-- Cheatsheet popup: shows a markdown file from cheatsheets/ (at the root of
-- this config, next to templates/) in a centered floating window.
--
--   require('custom.cheatsheet').open 'typst'   -- toggles cheatsheets/typst.md
--   require('custom.cheatsheet').pick()         -- choose from everything in cheatsheets/
--
-- To add another sheet, drop a .md file in cheatsheets/ -- no code changes.
-- It's an ordinary read-only buffer, so `/` search, scrolling and (if
-- render-markdown.nvim picks it up) rendered tables all work. `q` or <Esc>
-- closes it, and so does opening it again while it's showing.
-- ============================================================================

local M = {}

local win = nil

local function sheets_dir()
  return vim.fn.stdpath 'config' .. '/cheatsheets'
end

local function close()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  win = nil
end

function M.open(name)
  -- Toggle: a second press (from inside the popup, or anywhere) closes it.
  if win and vim.api.nvim_win_is_valid(win) then
    close()
    return
  end

  local path = sheets_dir() .. '/' .. name .. '.md'
  local f = io.open(path, 'r')
  if not f then
    vim.notify('Cheatsheet not found: ' .. path, vim.log.levels.WARN)
    return
  end
  local content = f:read '*a'
  f:close()

  local lines = vim.split(content, '\n', { plain = true })
  if lines[#lines] == '' then
    table.remove(lines) -- the file's final newline, not a real blank line
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = math.max(40, math.min(100, vim.o.columns - 8))
  local height = math.max(10, vim.o.lines - 8)
  win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    style = 'minimal',
    border = 'rounded',
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    title = ' ' .. name .. ' ',
    title_pos = 'center',
  })

  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'markdown'
  vim.bo[buf].modifiable = false

  -- Window options go AFTER filetype is set, on purpose: this config turns
  -- spell on for markdown from a FileType autocmd, which would otherwise
  -- underline half the code in the sheet. Likewise scrolloff = 999 (the
  -- typewriter scrolling from options.lua) would keep the cursor glued to
  -- the middle of a reference sheet.
  vim.wo[win].spell = false
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].cursorline = true
  vim.wo[win].scrolloff = 3

  for _, key in ipairs { 'q', '<Esc>' } do
    vim.keymap.set('n', key, close, { buffer = buf, nowait = true, desc = 'Close cheatsheet' })
  end

  -- Close when focus moves elsewhere (scheduled: closing a window from
  -- inside the autocmd that's leaving it is asking for trouble).
  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(close)
    end,
  })
end

function M.pick()
  local files = vim.fn.glob(sheets_dir() .. '/*.md', false, true)
  local names = vim.tbl_map(function(p)
    return vim.fn.fnamemodify(p, ':t:r')
  end, files)
  if #names == 0 then
    vim.notify('No cheatsheets in ' .. sheets_dir(), vim.log.levels.WARN)
    return
  end
  vim.ui.select(names, { prompt = 'Cheatsheet:' }, function(choice)
    if choice then
      M.open(choice)
    end
  end)
end

return M
