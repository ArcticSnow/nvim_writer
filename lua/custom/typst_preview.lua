-- ============================================================================
-- Live Typst preview, without a browser tab: watches the PDF that tinymist
-- keeps continuously fresh (exportPdf = "onType", set in lua/plugins/typst.lua),
-- rasterizes the current page, and shows it in a companion Kitty window via
-- Kitty's remote-control protocol -- the same mechanism kitty_room.lua (and
-- your main config's kitty_repl.lua) already use.
--
-- Requirements: Kitty with `allow_remote_control` on, and `pdftoppm`
-- (poppler-utils -- `apt install poppler-utils` / `brew install poppler`).
--
-- Design trade-off, stated plainly: each refresh CLOSES the previous preview
-- window and opens a new one, rather than updating one window's contents in
-- place. Kitty's overlay mechanism (`kitty @ launch --type=overlay`) can
-- probably do a smoother in-place update, but I couldn't confirm its exact
-- behavior across repeated calls confidently enough to ship it -- close/
-- reopen is slightly flickery but every command it relies on is one I've
-- directly verified exists. Refreshes are debounced (500ms) so fast typing
-- with exportPdf="onType" doesn't reopen the window on every keystroke.
-- ============================================================================

local M = {}

local PNG_PATH = vim.fn.stdpath 'cache' .. '/typst_preview.png'
local DEBOUNCE_MS = 500

local state = {
  active = false,
  window_id = nil,
  watcher = nil,
  debounce_timer = nil,
  page = 1,
  src_buf = nil,
}

local function in_kitty()
  return vim.env.TERM == 'xterm-kitty' or vim.env.KITTY_WINDOW_ID ~= nil
end

local function pdf_path_for(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  return (name:gsub('%.typ$', '')) .. '.pdf'
end

local function rasterize_and_show()
  if not state.active then
    return
  end
  local pdf = pdf_path_for(state.src_buf)
  if vim.fn.filereadable(pdf) == 0 then
    return
  end

  local prefix = PNG_PATH:gsub('%.png$', '')
  vim.system(
    { 'pdftoppm', '-f', tostring(state.page), '-l', tostring(state.page), '-r', '120', '-png', '-singlefile', pdf, prefix },
    {},
    vim.schedule_wrap(function(res)
      if not state.active or res.code ~= 0 or vim.fn.filereadable(PNG_PATH) == 0 then
        return
      end

      local old_window = state.window_id
      local launch = vim
        .system({
          'kitty',
          '@',
          'launch',
          '--type=window',
          '--title=Typst Preview (page ' .. state.page .. ')',
          '--hold',
          'kitten',
          'icat',
          PNG_PATH,
        }, { text = true })
        :wait()

      if launch.code == 0 then
        state.window_id = vim.trim(launch.stdout)
        if old_window then
          vim.system({ 'kitty', '@', 'close-window', '--match', 'id:' .. old_window }, {})
        end
      end
    end)
  )
end

local function schedule_refresh()
  if state.debounce_timer then
    state.debounce_timer:stop()
    state.debounce_timer:close()
  end
  state.debounce_timer = vim.uv.new_timer()
  state.debounce_timer:start(
    DEBOUNCE_MS,
    0,
    vim.schedule_wrap(function()
      if state.debounce_timer then
        state.debounce_timer:close()
        state.debounce_timer = nil
      end
      rasterize_and_show()
    end)
  )
end

function M.enable(bufnr)
  if state.active then
    return
  end
  if not in_kitty() then
    vim.notify('Typst preview needs Kitty (with allow_remote_control on)', vim.log.levels.WARN)
    return
  end
  if vim.fn.executable 'pdftoppm' == 0 then
    vim.notify('Typst preview needs `pdftoppm` (poppler-utils) installed', vim.log.levels.WARN)
    return
  end

  state.active = true
  state.src_buf = bufnr or vim.api.nvim_get_current_buf()
  state.page = 1

  local pdf = pdf_path_for(state.src_buf)
  local dir = vim.fn.fnamemodify(pdf, ':h')
  local target_name = vim.fn.fnamemodify(pdf, ':t')

  -- Watch the containing directory, not the file itself: tinymist may
  -- replace (rename into place), not just rewrite, the PDF on each export,
  -- which a direct file watch can miss after the first replacement.
  state.watcher = vim.uv.new_fs_event()
  state.watcher:start(
    dir,
    {},
    vim.schedule_wrap(function(err, filename)
      if not err and filename == target_name then
        schedule_refresh()
      end
    end)
  )

  rasterize_and_show() -- show whatever's already on disk immediately
end

function M.disable()
  if not state.active then
    return
  end
  state.active = false

  if state.watcher then
    state.watcher:stop()
    state.watcher = nil
  end
  if state.debounce_timer then
    state.debounce_timer:stop()
    state.debounce_timer:close()
    state.debounce_timer = nil
  end
  if state.window_id then
    vim.system({ 'kitty', '@', 'close-window', '--match', 'id:' .. state.window_id }, {})
    state.window_id = nil
  end
end

function M.toggle()
  if state.active then
    M.disable()
  else
    M.enable()
  end
end

function M.next_page()
  state.page = state.page + 1
  rasterize_and_show()
end

function M.prev_page()
  state.page = math.max(1, state.page - 1)
  rasterize_and_show()
end

return M
