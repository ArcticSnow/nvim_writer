-- ============================================================================
-- Dims every paragraph except the one the cursor is currently in, the way
-- iA Writer/Ulysses "Focus Mode" does. Built from scratch rather than pulled
-- from a plugin: it's two extmarks (everything above the current paragraph,
-- everything below it), recomputed on cursor movement by walking outward
-- from the cursor to the nearest blank lines -- O(paragraph length), not
-- O(document length), so it stays cheap regardless of document size.
-- ============================================================================

local M = {}

local ns = vim.api.nvim_create_namespace 'writer_paragraph_focus'
local group_name = 'writer-paragraph-focus'
local active = false

--- Walk outward from cursor_row (0-indexed) to the nearest blank lines.
local function paragraph_bounds(bufnr, cursor_row)
  local total = vim.api.nvim_buf_line_count(bufnr)

  local start_row = cursor_row
  while start_row > 0 do
    local line = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, start_row, false)[1] or ''
    if line:match '^%s*$' then
      break
    end
    start_row = start_row - 1
  end

  local end_row = cursor_row
  while end_row < total - 1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, end_row + 1, end_row + 2, false)[1] or ''
    if line:match '^%s*$' then
      break
    end
    end_row = end_row + 1
  end

  return start_row, end_row
end

local function apply()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local start_row, end_row = paragraph_bounds(bufnr, cursor_row)
  local total = vim.api.nvim_buf_line_count(bufnr)

  if start_row > 0 then
    vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
      end_row = start_row,
      end_col = 0,
      hl_group = 'WriterDimmed',
      hl_eol = true,
    })
  end
  if end_row < total - 1 then
    vim.api.nvim_buf_set_extmark(bufnr, ns, end_row + 1, 0, {
      end_row = total,
      end_col = 0,
      hl_group = 'WriterDimmed',
      hl_eol = true,
    })
  end
end

function M.enable()
  if active then
    return
  end
  active = true

  -- `default = true`: only sets this if you haven't already defined it
  -- yourself (e.g. in lua/plugins/colors.lua).
  vim.api.nvim_set_hl(0, 'WriterDimmed', { link = 'Comment', default = true })

  local group = vim.api.nvim_create_augroup(group_name, { clear = true })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'BufEnter' }, {
    group = group,
    callback = apply,
  })
  apply()
end

function M.disable()
  if not active then
    return
  end
  active = false
  pcall(vim.api.nvim_del_augroup_by_name, group_name)

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    end
  end
end

function M.toggle()
  if active then
    M.disable()
  else
    M.enable()
  end
end

return M
