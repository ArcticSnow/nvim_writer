-- ================================================================
-- bibtex_finder -- ported from your main config's lua/custom/bibtex_finder.lua,
-- unchanged in its core (search_and_insert, select_bib_file, the .bib parser),
-- plus two additions for this writing config:
--   - a small mtime-keyed cache, so preview_at_cursor() doesn't re-parse the
--     whole .bib file on every CursorHold
--   - preview_at_cursor(): a small floating window showing author/year/title
--     for the citation key under the cursor, wired to CursorHold from
--     lua/config/autocmds.lua so it acts like a hover
--
-- citation_format is switched between "[@%s]" (Markdown) and "@%s" (Typst)
-- automatically by lua/config/autocmds.lua.
-- ================================================================

local M = {}

M.config = {
  bib_file = nil, -- Will be determined automatically
  citation_format = '[@%s]',
}

--- Setup function to override defaults
---@param user_config table Configuration options
M.setup = function(user_config)
  M.config = vim.tbl_deep_extend('force', M.config, user_config or {})
end

--- Get bib file path from Quarto YAML header
local function get_quarto_bib_path()
  if vim.bo.filetype ~= 'quarto' then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, 10, false)

  for _, line in ipairs(lines) do
    local trimmed = line:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed:match '^bibliography:' then
      local bib_name = trimmed:match 'bibliography:%s*(.*)' or ''
      if bib_name ~= '' then
        local file_dir = vim.fn.fnamemodify(vim.fn.expand '%:p', ':h')
        if not vim.startswith(bib_name, '/') then
          return file_dir .. '/' .. bib_name
        else
          return bib_name
        end
      end
    end
  end

  return nil
end

local function file_exists(filepath)
  local file = io.open(filepath, 'r')
  if file then
    file:close()
    return true
  end
  return false
end

--- Change the bib file at runtime
M.change_bib_file = function(new_path)
  if file_exists(new_path) then
    M.config.bib_file = new_path
    vim.notify('BibTeX file changed to: ' .. vim.fn.fnamemodify(new_path, ':t'), vim.log.levels.INFO)
    return true
  else
    vim.notify('BibTeX file not found: ' .. new_path, vim.log.levels.ERROR)
    return false
  end
end

--- Interactive selection of bib file
M.select_bib_file = function()
  require('telescope.builtin').find_files {
    prompt_title = 'Select BibTeX File',
    find_command = { 'find', vim.fn.getcwd(), '-name', '*.bib', '-type', 'f' },
    previewer = true,
    layout_config = { height = 0.8, width = 0.8 },
    attach_mappings = function(_, map)
      map('i', '<CR>', function(prompt_bufnr)
        local selection = require('telescope.actions.state').get_selected_entry()
        require('telescope.actions').close(prompt_bufnr)
        if selection then
          M.change_bib_file(selection[1])
        end
      end)
      return true
    end,
  }
end

local function extract_field(entry, field_name)
  local pattern1 = field_name .. '={([^}]*)}'
  local pattern2 = field_name .. '="([^"]*)"'
  return entry:match(pattern1) or entry:match(pattern2) or ''
end

local function parse_bibtex_file(filepath)
  if not file_exists(filepath) then
    vim.notify('BibTeX file not found: ' .. filepath, vim.log.levels.ERROR)
    return {}
  end

  local file = io.open(filepath, 'r')
  if not file then
    vim.notify('Failed to open BibTeX file: ' .. filepath, vim.log.levels.ERROR)
    return {}
  end

  local content = file:read '*a'
  file:close()

  if #content == 0 then
    return {}
  end

  local entries = {}
  local current_entry = nil

  for line in content:gmatch '[^\n]+' do
    line = line:gsub('^%s+', ''):gsub('%s+$', '')

    if line == '' then
      if current_entry then
        table.insert(entries, current_entry)
        current_entry = nil
      end
      goto continue
    end

    if line:match '^@%a+' then
      if current_entry then
        table.insert(entries, current_entry)
      end
      current_entry = {
        key = line:match '@%a+{(.-),' or line:match '@%a+{(.-)}' or 'unknown',
        full = line,
      }
      current_entry.key = current_entry.key:gsub(' ', '')
    elseif current_entry then
      current_entry.full = current_entry.full .. '\n' .. line
    end

    ::continue::
  end

  if current_entry then
    table.insert(entries, current_entry)
  end

  local processed_entries = {}
  for _, entry in ipairs(entries) do
    local title = extract_field(entry.full, 'title')
    local year = extract_field(entry.full, 'year')
    local author = extract_field(entry.full, 'author')

    local display_key = entry.key
    if year and year ~= '' then
      display_key = entry.key .. '_' .. year
    end

    table.insert(processed_entries, {
      key = display_key,
      original_key = entry.key,
      title = title,
      author = author,
      year = year,
      full = entry.full,
      search_text = string.format('%s %s %s %s', entry.key, author, title, year),
    })
  end

  return processed_entries
end

-- Small cache so preview_at_cursor() (called from CursorHold, potentially
-- often) doesn't re-parse a possibly large .bib file every time.
local _cache = { path = nil, mtime = nil, entries = nil }

local function get_entries(bib_path)
  local mtime = vim.fn.getftime(bib_path)
  if _cache.path == bib_path and _cache.mtime == mtime and _cache.entries then
    return _cache.entries
  end
  local entries = parse_bibtex_file(bib_path)
  _cache = { path = bib_path, mtime = mtime, entries = entries }
  return entries
end

--- Resolve the current buffer's .bib path, prompting interactively as a last
--- resort. Returns nil (silently) if `silent` is true and nothing is found.
local function resolve_bib_path(silent)
  local bib_path = M.config.bib_file
  if bib_path and file_exists(bib_path) then
    return bib_path
  end

  local quarto_bib = get_quarto_bib_path()
  if quarto_bib and file_exists(quarto_bib) then
    M.config.bib_file = quarto_bib
    return quarto_bib
  end

  if not silent then
    M.select_bib_file()
  end
  return nil
end

--- Open Telescope to search and insert BibTeX references
M.search_and_insert = function()
  local bib_path = resolve_bib_path(false)
  if not bib_path then
    return
  end

  local entries = get_entries(bib_path)
  if not entries or #entries == 0 then
    vim.notify('No BibTeX entries found in ' .. bib_path, vim.log.levels.WARN)
    return
  end

  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Zotero References',
      finder = require('telescope.finders').new_table {
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry,
            display = string.format('%s: %s', entry.key, entry.title),
            ordinal = entry.search_text,
          }
        end,
      },
      sorter = require('telescope.config').values.generic_sorter(),
      attach_mappings = function(prompt_bufnr)
        require('telescope.actions').select_default:replace(function()
          local selection = require('telescope.actions.state').get_selected_entry()
          require('telescope.actions').close(prompt_bufnr)
          local citation = string.format(M.config.citation_format, selection.value.original_key)
          vim.api.nvim_put({ citation }, 'c', true, true)
        end)
        return true
      end,
      previewer = require('telescope.previewers').new_buffer_previewer {
        define_preview = function(self, entry)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.value.full, '\n'))
          vim.bo[self.state.bufnr].filetype = 'bib'
        end,
      },
    })
    :find()
end

--- Find the citation key under the cursor, in either "[@key]" (Markdown) or
--- bare "@key" (Typst) form.
local function citation_key_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  for s, key, e in line:gmatch '()%[@([%w_:%-%.]+)%]()' do
    if col >= s and col <= e then
      return key
    end
  end
  for s, key, e in line:gmatch '()@([%w_:%-%.]+)()' do
    if col >= s and col <= e then
      return key
    end
  end
  return nil
end

--- Show a small floating window with author/year/title for the citation
--- under the cursor. No-ops quietly if there's nothing to show -- this is
--- meant to feel like ambient hover info, not a command you run.
M.preview_at_cursor = function()
  local key = citation_key_under_cursor()
  if not key then
    return
  end

  local bib_path = resolve_bib_path(true)
  if not bib_path then
    return
  end

  local entries = get_entries(bib_path)
  local match
  for _, e in ipairs(entries) do
    if e.original_key == key then
      match = e
      break
    end
  end
  if not match then
    return
  end

  local byline = match.author ~= '' and match.author or 'Unknown author'
  if match.year ~= '' then
    byline = byline .. ' (' .. match.year .. ')'
  end
  local title = match.title ~= '' and match.title or '(no title)'

  vim.lsp.util.open_floating_preview({ title, byline }, 'markdown', {
    border = 'rounded',
    max_width = 60,
    focus = false,
    focusable = false,
  })
end

--- Wire preview_at_cursor() to CursorHold for the current buffer. Called
--- once per prose buffer from lua/config/autocmds.lua.
M.attach_cursor_preview = function()
  vim.api.nvim_create_autocmd('CursorHold', {
    buffer = 0,
    group = vim.api.nvim_create_augroup('writer-citation-preview', { clear = false }),
    callback = M.preview_at_cursor,
  })
end

return M
