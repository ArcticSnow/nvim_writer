-- ============================================================================
-- A toggleable outline in a side panel -- not a Telescope picker (that's a
-- "look something up and jump" tool; this is "keep the shape of the document
-- visible while I write"). Parses headings directly (Markdown "#", Typst
-- "="), no LSP/treesitter dependency. Follows whichever prose buffer is
-- active, and its own cursor tracks your position in the source buffer, so
-- glancing at it tells you both structure and "where am I".
-- ============================================================================

local M = {}

local WIDTH = 32

local state = {
  win = nil,
  buf = nil,
  src_buf = nil,
  src_win = nil,
  headings = {},
}

local function parse_headings(bufnr)
  local ft = vim.bo[bufnr].filetype
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local headings = {}
  for i, line in ipairs(lines) do
    local level, text
    if ft == 'typst' then
      level, text = line:match '^(=+)%s+(.*)$'
    else -- markdown, quarto
      level, text = line:match '^(#+)%s+(.*)$'
    end
    if level and text and text ~= '' then
      table.insert(headings, { line = i, level = #level, text = text })
    end
  end
  return headings
end

local function render()
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    return
  end
  local lines = {}
  for _, h in ipairs(state.headings) do
    table.insert(lines, string.rep('  ', h.level - 1) .. h.text)
  end
  if #lines == 0 then
    lines = { '(no headings yet)' }
  end
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
end

local function refresh()
  if not (state.src_buf and vim.api.nvim_buf_is_valid(state.src_buf)) then
    return
  end
  state.headings = parse_headings(state.src_buf)
  render()
end

--- Move the outline's own cursor to whichever heading contains the source
--- buffer's cursor. Relies on the outline window's native 'cursorline' to
--- show it -- windows render their own cursorline even when unfocused, so
--- this works as ambient position feedback while you keep typing elsewhere.
local function sync_position()
  if not (state.win and vim.api.nvim_win_is_valid(state.win)) then
    return
  end
  if not (state.src_win and vim.api.nvim_win_is_valid(state.src_win)) then
    return
  end
  local cursor_line = vim.api.nvim_win_get_cursor(state.src_win)[1]
  local idx
  for i, h in ipairs(state.headings) do
    if h.line <= cursor_line then
      idx = i
    else
      break
    end
  end
  if idx then
    pcall(vim.api.nvim_win_set_cursor, state.win, { idx, 0 })
  end
end

local function is_prose_filetype(ft)
  return ft == 'markdown' or ft == 'quarto' or ft == 'typst'
end

function M.open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    return
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  if not is_prose_filetype(vim.bo[cur_buf].filetype) then
    vim.notify('Outline: not a Markdown/Typst buffer', vim.log.levels.WARN)
    return
  end
  state.src_buf = cur_buf
  state.src_win = vim.api.nvim_get_current_win()

  vim.cmd 'topleft vsplit'
  vim.cmd('vertical resize ' .. WIDTH)
  state.win = vim.api.nvim_get_current_win()
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(state.win, state.buf)

  vim.bo[state.buf].buftype = 'nofile'
  vim.bo[state.buf].bufhidden = 'wipe'
  vim.bo[state.buf].swapfile = false
  vim.bo[state.buf].filetype = 'writer-outline'
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = 'no'
  vim.wo[state.win].wrap = false
  vim.wo[state.win].cursorline = true
  vim.wo[state.win].winfixwidth = true

  vim.keymap.set('n', '<CR>', function()
    local row = vim.api.nvim_win_get_cursor(state.win)[1]
    local h = state.headings[row]
    if h and state.src_win and vim.api.nvim_win_is_valid(state.src_win) then
      vim.api.nvim_set_current_win(state.src_win)
      vim.api.nvim_win_set_cursor(state.src_win, { h.line, 0 })
      vim.cmd 'normal! zz'
    end
  end, { buffer = state.buf, desc = 'Jump to heading' })
  vim.keymap.set('n', 'q', M.close, { buffer = state.buf, desc = 'Close outline' })
  vim.keymap.set('n', 'r', refresh, { buffer = state.buf, desc = 'Refresh outline' })

  refresh()
  sync_position()

  local group = vim.api.nvim_create_augroup('writer-outline-panel', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
    group = group,
    buffer = state.src_buf,
    callback = refresh,
  })
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = group,
    buffer = state.src_buf,
    callback = sync_position,
  })
  -- Follow whichever prose buffer becomes active, so the panel stays useful
  -- if you switch files with the outline open.
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function(args)
      if not (state.win and vim.api.nvim_win_is_valid(state.win)) then
        return
      end
      if args.buf == state.buf or args.buf == state.src_buf then
        return
      end
      if is_prose_filetype(vim.bo[args.buf].filetype) then
        state.src_buf = args.buf
        state.src_win = vim.api.nvim_get_current_win()
        refresh()
        sync_position()
      end
    end,
  })

  vim.api.nvim_set_current_win(state.src_win)
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win, state.buf = nil, nil
  pcall(vim.api.nvim_del_augroup_by_name, 'writer-outline-panel')
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.close()
  else
    M.open()
  end
end

return M
