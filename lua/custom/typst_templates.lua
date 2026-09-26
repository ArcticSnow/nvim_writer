-- ============================================================================
-- Insert a Typst document template at the cursor -- the same pattern as the
-- coding config's templater.lua (Telescope picker over a templates/ folder,
-- %{variable} placeholder substitution), rebuilt fresh here rather than
-- copied byte-for-byte (I didn't have that file loaded this session --
-- share it if you want this brought even closer in line with it).
--
-- Templates live in templates/ at the root of this config (NOT under lua/),
-- matching the coding config's convention. See that folder for what's
-- there now: article, letter, report, slides, blank.
--
-- Placeholders use %{name} (same syntax as the coding config's templates,
-- e.g. templates/lua_plugins.lua's "Author: %{author}"). %{date} and
-- %{author} resolve automatically; anything else prompts once per unique
-- name via vim.ui.input, so a new template with a new placeholder (like
-- %{recipient} in letter.typ) just works without touching this file.
-- ============================================================================

local M = {}

-- Edit this once rather than being prompted for it on every template.
local AUTHOR_NAME = 'Your Name'

local auto_values = {
  date = function()
    return os.date '%Y-%m-%d'
  end,
  author = function()
    return AUTHOR_NAME
  end,
}

local function templates_dir()
  return vim.fn.stdpath 'config' .. '/templates'
end

--- Find every unique %{name} placeholder in content, in first-seen order.
local function collect_placeholders(content)
  local seen = {}
  local order = {}
  for name in content:gmatch '%%{(%w+)}' do
    if not seen[name] then
      seen[name] = true
      table.insert(order, name)
    end
  end
  return order
end

--- Resolve placeholders[idx..] one at a time (auto-filled or prompted),
--- then call finish(values) once all are resolved. Recursive rather than a
--- loop since vim.ui.input is asynchronous -- each prompt has to wait for
--- the previous one to answer before the next can appear.
local function resolve_placeholders(placeholders, idx, values, finish)
  if idx > #placeholders then
    finish(values)
    return
  end

  local name = placeholders[idx]
  local auto = auto_values[name]
  if auto then
    values[name] = auto()
    resolve_placeholders(placeholders, idx + 1, values, finish)
  else
    local label = name:sub(1, 1):upper() .. name:sub(2)
    vim.ui.input({ prompt = label .. ': ' }, function(input)
      values[name] = input or ''
      resolve_placeholders(placeholders, idx + 1, values, finish)
    end)
  end
end

--- Read a template file, resolve its placeholders, and insert the result
--- at the cursor in the current buffer.
function M.insert(filepath)
  local f = io.open(filepath, 'r')
  if not f then
    vim.notify('Could not read template: ' .. filepath, vim.log.levels.ERROR)
    return
  end
  local content = f:read '*a'
  f:close()

  local placeholders = collect_placeholders(content)
  resolve_placeholders(placeholders, 1, {}, function(values)
    local final = content:gsub('%%{(%w+)}', function(name)
      return values[name] or ''
    end)
    -- strip a single trailing newline so we don't leave an extra blank line
    final = final:gsub('\n$', '')
    local lines = vim.split(final, '\n', { plain = true })
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row, row, false, lines)
  end)
end

--- Open a Telescope picker over templates/ and insert whichever is chosen.
function M.pick()
  local dir = templates_dir()
  if vim.fn.isdirectory(dir) == 0 then
    vim.notify('No templates/ folder found at ' .. dir, vim.log.levels.WARN)
    return
  end

  require('telescope.builtin').find_files {
    prompt_title = 'Typst Templates',
    cwd = dir,
    attach_mappings = function(_, map)
      require('telescope.actions').select_default:replace(function(prompt_bufnr)
        local selection = require('telescope.actions.state').get_selected_entry()
        require('telescope.actions').close(prompt_bufnr)
        if selection then
          M.insert(dir .. '/' .. selection[1])
        end
      end)
      return true
    end,
  }
end

return M
