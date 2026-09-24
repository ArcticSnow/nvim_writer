-- ============================================================================
-- "Typographic autocorrect": turns `--` into an en dash, `---`/`--`+`-` into
-- an em dash, `...` into a real ellipsis, and straight quotes into curly ones
-- as you type -- the small detail that makes a draft feel typeset rather
-- than drafted.
--
-- Markdown/Quarto only, deliberately -- Typst renders its own smart quotes
-- at compile time from straight source quotes, so converting them in the
-- .typ source would fight the tool rather than help it.
--
-- Guarded against fenced code blocks / inline code spans via treesitter, so
-- your `--verbose` flags don't turn into en dashes.
-- ============================================================================

local M = {}

local group_name = 'writer-smart-typography'
local active = false

local function in_code_context()
  local ok, node = pcall(vim.treesitter.get_node, {})
  if not ok or not node then
    return false
  end
  local n = node
  while n do
    local t = n:type()
    if t == 'fenced_code_block' or t == 'code_span' or t == 'indented_code_block' then
      return true
    end
    n = n:parent()
  end
  return false
end

local function replace_tail(line, col, tail_byte_len, replacement)
  local head = line:sub(1, col - tail_byte_len)
  local rest = line:sub(col + 1)
  vim.api.nvim_set_current_line(head .. replacement .. rest)
  local win = vim.api.nvim_get_current_win()
  local row = vim.api.nvim_win_get_cursor(win)[1]
  vim.api.nvim_win_set_cursor(win, { row, col - tail_byte_len + #replacement })
end

local function on_text_changed()
  if in_code_context() then
    return
  end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = line:sub(1, col)

  if vim.endswith(before, '\226\128\147-') then -- en dash (–) + fresh "-" => em dash
    replace_tail(line, col, #'\226\128\147-', '\226\128\148') -- —
  elseif vim.endswith(before, '--') then
    replace_tail(line, col, #'--', '\226\128\147') -- –
  elseif vim.endswith(before, '...') then
    replace_tail(line, col, #'...', '\226\128\166') -- …
  elseif before:sub(-1) == '"' then
    local prev = before:sub(-2, -2)
    local is_open = prev == '' or prev:match '%s' or prev:match '[%(%[{]'
    replace_tail(line, col, 1, is_open and '\226\128\156' or '\226\128\157') -- " or "
  elseif before:sub(-1) == "'" then
    local prev = before:sub(-2, -2)
    -- a letter/digit before it means it's an apostrophe (don't, '90s) -> closing quote
    local is_apostrophe_or_close = prev:match '[%w]'
    replace_tail(line, col, 1, is_apostrophe_or_close and '\226\128\153' or '\226\128\152') -- ’ or ‘
  end
end

function M.enable()
  if active then
    return
  end
  active = true
  local group = vim.api.nvim_create_augroup(group_name, { clear = true })
  vim.api.nvim_create_autocmd('TextChangedI', {
    group = group,
    callback = function()
      if vim.bo.filetype == 'markdown' or vim.bo.filetype == 'quarto' then
        on_text_changed()
      end
    end,
  })
end

function M.disable()
  if not active then
    return
  end
  active = false
  pcall(vim.api.nvim_del_augroup_by_name, group_name)
end

function M.toggle()
  if active then
    M.disable()
  else
    M.enable()
  end
end

return M
