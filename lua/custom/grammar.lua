-- ============================================================================
-- On-demand grammar checking with LTeX+ (LanguageTool, run locally).
-- English and French, Markdown and Typst.
--
-- STARTING AND STOPPING
--   <leader>gc   check this document (starts the checker if it isn't running)
--   <leader>gs   stop the checker now
--   <leader>gq   list every issue in the location list
--   <leader>gl   switch this document's language, en <-> fr (writing_language.lua)
--   :GrammarCheck / :GrammarStop / :GrammarList   same, as commands
--
-- Nothing runs at startup. LTeX+ is a Java process holding LanguageTool's
-- rules in memory: measured ~700 MB with one language loaded, ~1 GB with
-- English and French both loaded. It starts on <leader>gc (the first check
-- takes ~10-15 s while Java and LanguageTool load; later documents reuse it)
-- and stops itself after `idle_minutes` without grammar activity, or when
-- you close the last checked document.
--
-- GOING THROUGH ISSUES (like spelling's ]s / z=)
--   ]g  [g       next / previous issue (a popup shows the message and fixes)
--   ]G  [G       last / first issue
--   1g=  2g=     apply fix number 1, 2, ... to the issue under the cursor
--   g=           menu: the fixes, plus "Ignore here" / "Ignore this rule"
--   .            repeat your last g= choice on the issue under the cursor,
--                so  ]g 1g=  ]g .  ]g .  works through similar mistakes
--   u            undo a fix, as usual
-- These keys exist only in documents being checked. "Ignore here" and
-- "Ignore this rule" are remembered across sessions, in
-- stdpath('data')/ltex-plus/state.json.
--
-- WHEN IT RE-CHECKS
--   Markdown: on every save. LTeX+ only re-checks the paragraphs that changed
--     (measured ~0.1 s on a 16 kB file), and auto-save saves ~1 s after you
--     stop typing, so it's effectively live.
--   Typst: LTeX+ re-checks the WHOLE document on any change (measured ~2 s
--     for 16 kB, ~5 s for 40 kB), so instead of every save it re-checks once
--     you've paused for `typst_pause_ms`, and shortly after you apply fixes.
-- Fixes apply instantly whatever the re-check time: each issue is tracked
-- with its own mark that follows your edits, so underlines stay in place,
-- an issue disappears as soon as you fix or edit it, and a fix is applied
-- only if the flagged text is still exactly there.
--
-- LANGUAGE: per document, from writing_language.lua (b:writer_lang, auto-
-- detected or <leader>gl); switching re-checks in the new language. One
-- exception: in Markdown, LTeX+ obeys a front-matter `lang:` line over what
-- Neovim tells it, so change the language there.
--
-- SPELLING stays with Neovim's own spell checker (`zg` remains your one
-- dictionary); LanguageTool's spelling rules are turned off.
--
-- Install: Mason package `ltex-ls-plus` (see ensure_installed in
-- lua/plugins/typst.lua). Its download includes its own Java (~320 MB).
-- ============================================================================

local M = {}

M.opts = {
  cmd = 'ltex-ls-plus', -- on PATH via Mason
  filetypes = { markdown = true, typst = true },
  idle_minutes = 10, -- stop the server after this long without grammar activity
  -- Java heap cap. 512m is enough for one language but ran out of memory
  -- (OutOfMemoryError, checks stalling) once English and French were both
  -- loaded; 1g handled both with no slowdown.
  heap = '1g',
  typst_pause_ms = 4000, -- Typst: re-check after you stop editing this long
  fix_recheck_ms = 1500, -- re-check this long after your last fix
  english = 'en-US', -- or 'en-GB'
  -- Set to 'fr' to also flag French->English false friends in English text
  -- (e.g. "actually" used for "actuellement").
  mother_tongue = nil,
}

local NAME = 'ltex_plus'
local KEYS = { ']g', '[g', ']G', '[G', 'g=' }

-- LanguageTool's spelling rules, disabled so native `spell` is the only speller.
local SPELLING_RULES = {
  ['en-US'] = { 'MORFOLOGIK_RULE_EN_US' },
  ['en-GB'] = { 'MORFOLOGIK_RULE_EN_GB' },
  fr = { 'FR_SPELLING_RULE' },
}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

-- ---------------------------------------------------------------------------
-- Persistent state: rules you disabled and false positives you hid.
-- ---------------------------------------------------------------------------
local state_file = vim.fs.joinpath(vim.fn.stdpath 'data', 'ltex-plus', 'state.json')
local state -- { disabledRules = {lang = {...}}, hiddenFalsePositives = {...}, dictionary = {...} }

local function load_state()
  if state then
    return state
  end
  state = { disabledRules = {}, hiddenFalsePositives = {}, dictionary = {} }
  local f = io.open(state_file, 'r')
  if f then
    local ok, decoded = pcall(vim.json.decode, f:read '*a')
    f:close()
    if ok and type(decoded) == 'table' then
      state = vim.tbl_extend('force', state, decoded)
    end
  end
  return state
end

local function save_state()
  vim.fn.mkdir(vim.fs.dirname(state_file), 'p')
  local f = io.open(state_file, 'w')
  if f then
    f:write(vim.json.encode(state))
    f:close()
  end
end

-- Merge { lang = { items } } into state[key], without duplicates.
local function remember(key, by_lang)
  load_state()
  for lang, items in pairs(by_lang or {}) do
    local list = state[key][lang] or {}
    for _, item in ipairs(items) do
      if not vim.list_contains(list, item) then
        table.insert(list, item)
      end
    end
    state[key][lang] = list
  end
  save_state()
end

-- ---------------------------------------------------------------------------
-- Per-document settings
-- ---------------------------------------------------------------------------
local function ltex_language(buf)
  local lang = vim.b[buf].writer_lang
  if not lang then -- writing_language.lua not loaded: fall back on spelllang
    lang = vim.bo[buf].spelllang:match '^fr' and 'fr' or 'en'
  end
  return lang == 'fr' and 'fr' or M.opts.english
end

local function settings_for(buf)
  load_state()
  local lang = ltex_language(buf)
  local disabled = vim.list_extend(vim.deepcopy(SPELLING_RULES[lang] or {}), state.disabledRules[lang] or {})
  return {
    language = lang,
    -- Markdown re-checks cheaply on save; Typst re-checks are whole-document,
    -- so they're scheduled by this module instead (see schedule_recheck).
    checkFrequency = vim.bo[buf].filetype == 'markdown' and 'save' or 'manual',
    completionEnabled = false,
    disabledRules = { [lang] = disabled },
    hiddenFalsePositives = { [lang] = state.hiddenFalsePositives[lang] or {} },
    dictionary = { [lang] = state.dictionary[lang] or {} },
    additionalRules = { motherTongue = M.opts.mother_tongue },
  }
end

-- LTeX+ asks for settings per document (scopeUri), so each buffer can
-- answer with its own language.
local function on_configuration(_, params)
  local result = {}
  for _, item in ipairs(params.items or {}) do
    if item.section == 'ltex' then
      local buf = item.scopeUri and vim.uri_to_bufnr(item.scopeUri) or vim.api.nvim_get_current_buf()
      table.insert(result, settings_for(buf))
    else
      table.insert(result, vim.NIL)
    end
  end
  return result
end

-- ---------------------------------------------------------------------------
-- Client
-- ---------------------------------------------------------------------------
local function get_client()
  return vim.lsp.get_clients({ name = NAME })[1]
end

local function attached(buf)
  local client = get_client()
  return client and client.attached_buffers[buf] and client or nil
end

local idle_timer
local function stop(reason) end -- defined below
local function touch()
  if not idle_timer then
    idle_timer = vim.uv.new_timer()
  end
  idle_timer:stop()
  idle_timer:start(
    M.opts.idle_minutes * 60 * 1000,
    0,
    vim.schedule_wrap(function()
      stop(('idle %s min'):format(M.opts.idle_minutes))
    end)
  )
end

local function buf_text(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n') .. '\n'
end

-- changedtick of the text the server last checked, per buffer. A result is
-- only trusted if the buffer hasn't changed since; otherwise its positions
-- could point at the wrong words.
local sent_tick = {}

-- Ask for a check of the buffer's CURRENT text. (Without `text`, LTeX+ reads
-- the file from disk, which can be behind the buffer.)
local function check_document(client, buf)
  sent_tick[buf] = vim.b[buf].changedtick
  client:request('workspace/executeCommand', {
    command = '_ltex.checkDocument',
    arguments = { { uri = vim.uri_from_bufnr(buf), codeLanguageId = vim.bo[buf].filetype, text = buf_text(buf) } },
  }, function() end, buf)
end

local recheck_timers = {}
local function schedule_recheck(buf, ms)
  local t = recheck_timers[buf] or vim.uv.new_timer()
  recheck_timers[buf] = t
  t:stop()
  t:start(
    ms,
    0,
    vim.schedule_wrap(function()
      local client = vim.api.nvim_buf_is_valid(buf) and attached(buf)
      if not client or vim.b[buf].changedtick == sent_tick[buf] then
        return -- stopped, or this exact text was already checked
      end
      if vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' then
        return schedule_recheck(buf, ms) -- still typing
      end
      check_document(client, buf)
    end)
  )
end

local function cancel_recheck(buf)
  local t = recheck_timers[buf]
  if t then
    t:stop()
    t:close()
    recheck_timers[buf] = nil
  end
end

-- After a settings change (rule disabled, language switched) LTeX+ re-reads
-- every document's settings and re-checks them.
local function refresh(client)
  client:notify('workspace/didChangeConfiguration', { settings = { ltex = {} } })
end

-- Client-side commands behind LTeX+'s "Ignore" code actions.
local function remember_and_refresh(key, field)
  return function(command)
    remember(key, command.arguments[1][field])
    local client = get_client()
    if client then
      refresh(client)
    end
  end
end

local commands = {
  ['_ltex.disableRules'] = remember_and_refresh('disabledRules', 'ruleIds'),
  ['_ltex.hideFalsePositives'] = remember_and_refresh('hiddenFalsePositives', 'falsePositives'),
  ['_ltex.addToDictionary'] = remember_and_refresh('dictionary', 'words'),
}

-- ---------------------------------------------------------------------------
-- Tracked issues: one extmark per issue, following the text as you edit.
-- ---------------------------------------------------------------------------
local NS = vim.api.nvim_create_namespace 'writer-grammar'
local NS_POPUP = vim.api.nvim_create_namespace 'writer-grammar-popup'
local issues = {} -- [buf] = { [mark_id] = { diag, text, tick, actions } }
local pending_report = {} -- [buf] = true while waiting to announce a check's result

local function text_in(buf, sr, sc, er, ec)
  local ok, t = pcall(vim.api.nvim_buf_get_text, buf, sr, sc, er, ec, {})
  return ok and table.concat(t, '\n') or nil
end

local function drop(buf, id)
  pcall(vim.api.nvim_buf_del_extmark, buf, NS, id)
  if issues[buf] then
    issues[buf][id] = nil
  end
end

local function clear(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
  end
  issues[buf] = nil
end

--- Issues still valid, in document order. An issue whose text you've edited
--- is dropped (and its underline with it).
local function live(buf)
  local list = {}
  for id, rec in pairs(issues[buf] or {}) do
    local m = vim.api.nvim_buf_get_extmark_by_id(buf, NS, id, { details = true })
    local sr, sc = m[1], m[2]
    local er, ec = m[3] and m[3].end_row, m[3] and m[3].end_col
    if sr and er and (rec.text == '' or text_in(buf, sr, sc, er, ec) == rec.text) then
      table.insert(list, { id = id, rec = rec, sr = sr, sc = sc, er = er, ec = ec })
    else
      drop(buf, id)
    end
  end
  table.sort(list, function(a, b)
    return a.sr < b.sr or (a.sr == b.sr and a.sc < b.sc)
  end)
  return list
end

local function by_id(buf, id)
  for _, it in ipairs(live(buf)) do
    if it.id == id then
      return it
    end
  end
end

local function issue_at_cursor(buf)
  local pos = vim.api.nvim_win_get_cursor(0)
  local r, c = pos[1] - 1, pos[2]
  for _, it in ipairs(live(buf)) do
    local after_start = r > it.sr or (r == it.sr and c >= it.sc)
    local before_end = r < it.er or (r == it.er and c < it.ec)
    if after_start and before_end then
      return it
    end
  end
end

-- Sort LTeX+'s code actions into fixes and the two "ignore" commands.
local function parse_actions(result, uri)
  local acts = { fixes = {} }
  for _, a in ipairs(result or {}) do
    local cmd = type(a.command) == 'table' and a.command or (type(a.command) == 'string' and a) or nil
    if a.edit then
      local edits = a.edit.changes and a.edit.changes[uri]
      for _, dc in ipairs(a.edit.documentChanges or {}) do
        edits = edits or dc.edits
      end
      if edits and #edits == 1 then
        table.insert(acts.fixes, { label = a.title:match "^Use '(.*)'$" or a.title, edit = edits[1] })
      end
    elseif cmd and cmd.command == '_ltex.hideFalsePositives' then
      acts.hide = cmd
    elseif cmd and cmd.command == '_ltex.disableRules' then
      acts.disable = cmd
    end
  end
  return acts
end

local function fetch_actions(client, buf, rec, cb)
  local uri = vim.uri_from_bufnr(buf)
  client:request('textDocument/codeAction', {
    textDocument = { uri = uri },
    range = rec.diag.user_data.lsp.range,
    context = { diagnostics = { rec.diag.user_data.lsp } },
  }, function(err, result)
    if not err then
      rec.actions = parse_actions(result, uri)
      if cb then
        cb()
      end
    end
  end, buf)
end

-- Turn a fresh LTeX+ result into tracked issues, and fetch every issue's
-- fixes now, while the server's text still matches the buffer.
local function rebuild(buf, client)
  clear(buf)
  issues[buf] = {}
  local tick = vim.b[buf].changedtick
  for _, d in ipairs(vim.diagnostic.get(buf, { namespace = vim.lsp.diagnostic.get_namespace(client.id) })) do
    local ok, id = pcall(vim.api.nvim_buf_set_extmark, buf, NS, d.lnum, d.col, {
      end_row = d.end_lnum,
      end_col = d.end_col,
      hl_group = 'GrammarIssue',
      priority = 140,
    })
    if ok then
      local rec = { diag = d, text = text_in(buf, d.lnum, d.col, d.end_lnum, d.end_col) or '', tick = tick }
      issues[buf][id] = rec
      fetch_actions(client, buf, rec)
    end
  end
end

local function on_publish(buf)
  local client = vim.api.nvim_buf_is_valid(buf) and attached(buf)
  if not client then
    return
  end
  touch()
  if vim.b[buf].changedtick ~= sent_tick[buf] then
    -- You edited while it was checking: re-check the current text instead.
    schedule_recheck(buf, M.opts.fix_recheck_ms)
    return
  end
  rebuild(buf, client)
  if pending_report[buf] then
    pending_report[buf] = nil
    local n = vim.tbl_count(issues[buf])
    notify(
      ('Grammar (%s): %s'):format(
        ltex_language(buf),
        n == 0 and 'no issues' or (('%d issue%s. ]g to go through them.'):format(n, n == 1 and '' or 's'))
      )
    )
  end
end

-- ---------------------------------------------------------------------------
-- Popup shown when landing on an issue
-- ---------------------------------------------------------------------------
local function wrap(text, width)
  local lines, line = {}, ''
  for word in text:gmatch '%S+' do
    if line ~= '' and #line + 1 + #word > width then
      table.insert(lines, line)
      line = word
    else
      line = line == '' and word or (line .. ' ' .. word)
    end
  end
  if line ~= '' then
    table.insert(lines, line)
  end
  return lines
end

local function render_popup(buf, it)
  -- Only if we're still on that issue.
  local pos = vim.api.nvim_win_get_cursor(0)
  if vim.api.nvim_get_current_buf() ~= buf or pos[1] - 1 ~= it.sr or pos[2] ~= it.sc then
    return
  end
  local lines, hls = wrap(it.rec.diag.message, 64), {}
  local fixes = it.rec.actions and it.rec.actions.fixes
  if not fixes then
    table.insert(lines, 'loading fixes...')
    table.insert(hls, { #lines - 1, 0, -1, 'Comment' })
  elseif #fixes == 0 then
    table.insert(lines, 'No suggested fix: edit by hand, or g= to ignore.')
    table.insert(hls, { #lines - 1, 0, -1, 'Comment' })
  else
    for i, f in ipairs(fixes) do
      table.insert(lines, ('%d  %s'):format(i, f.label))
      table.insert(hls, { #lines - 1, 0, #tostring(i), 'Number' })
    end
    table.insert(lines, 'Ng= apply fix N  ·  g= menu  ·  . repeat')
    table.insert(hls, { #lines - 1, 0, -1, 'Comment' })
  end
  local fbuf = vim.lsp.util.open_floating_preview(lines, 'text', {
    focus = false,
    border = 'rounded',
    max_width = 72,
    close_events = { 'CursorMoved', 'CursorMovedI', 'InsertEnter' },
  })
  for _, h in ipairs(hls) do
    local row, s, e, group = unpack(h)
    local line = vim.api.nvim_buf_get_lines(fbuf, row, row + 1, false)[1] or ''
    pcall(vim.api.nvim_buf_set_extmark, fbuf, NS_POPUP, row, s, { end_col = e == -1 and #line or e, hl_group = group })
  end
end

local function show_popup(buf, it)
  -- Scheduled, like Neovim's own jump popups: opening it right away would let
  -- the jump's own CursorMoved event close it again.
  vim.schedule(function()
    if it.rec.actions then
      render_popup(buf, it)
    else
      local client = attached(buf)
      if client then
        fetch_actions(client, buf, it.rec, vim.schedule_wrap(function()
          render_popup(buf, it)
        end))
      end
    end
  end)
end

-- ---------------------------------------------------------------------------
-- Navigation
-- ---------------------------------------------------------------------------
local function goto_issue(buf, it)
  vim.cmd "normal! m'" -- jumplist, so `` / <C-o> go back
  vim.api.nvim_win_set_cursor(0, { it.sr + 1, it.sc })
  vim.cmd 'normal! zv' -- open folds
  touch()
  show_popup(buf, it)
end

local function step(dir, count)
  local buf = vim.api.nvim_get_current_buf()
  local list = live(buf)
  if #list == 0 then
    notify 'No grammar issues left in this document.'
    return
  end
  local pos = vim.api.nvim_win_get_cursor(0)
  local r, c = pos[1] - 1, pos[2]
  local idx
  if dir > 0 then
    for i, it in ipairs(list) do
      if it.sr > r or (it.sr == r and it.sc > c) then
        idx = i
        break
      end
    end
    idx = ((idx or 1) - 1 + (count - 1)) % #list + 1 -- wraps around, like ]s
  else
    for i = #list, 1, -1 do
      local it = list[i]
      if it.sr < r or (it.sr == r and it.sc < c) then
        idx = i
        break
      end
    end
    idx = ((idx or #list) - 1 - (count - 1)) % #list + 1
  end
  goto_issue(buf, list[idx])
end

function M.next(count)
  step(1, count or 1)
end
function M.prev(count)
  step(-1, count or 1)
end
function M.first()
  local buf = vim.api.nvim_get_current_buf()
  local list = live(buf)
  if list[1] then
    goto_issue(buf, list[1])
  else
    notify 'No grammar issues left in this document.'
  end
end
function M.last()
  local buf = vim.api.nvim_get_current_buf()
  local list = live(buf)
  if list[#list] then
    goto_issue(buf, list[#list])
  else
    notify 'No grammar issues left in this document.'
  end
end

-- ---------------------------------------------------------------------------
-- Fixing: g=, Ng=, and . to repeat
-- ---------------------------------------------------------------------------
local last_choice -- { kind = 'fix', n = N } | { kind = 'hide' } | { kind = 'disable' }

local function apply(buf, it, choice)
  if not it then
    notify 'No grammar issue under the cursor (]g goes to the next one).'
    return
  end
  local acts = it.rec.actions
  if not acts then
    notify 'Fixes for this issue are still loading; try again in a moment.'
    return
  end
  local client = get_client()
  if not client then
    return
  end

  if choice.kind == 'fix' then
    local fix = acts.fixes[choice.n]
    if not fix then
      notify(#acts.fixes == 0 and 'No suggested fix for this one: edit by hand, or g= to ignore.'
        or ('Only %d fix%s here.'):format(#acts.fixes, #acts.fixes == 1 and '' or 'es'))
      return
    end
    local e = fix.edit
    if vim.deep_equal(e.range, it.rec.diag.user_data.lsp.range) then
      -- The usual case: the fix replaces exactly the flagged text, which is
      -- wherever the mark says it is now.
      vim.api.nvim_buf_set_text(buf, it.sr, it.sc, it.er, it.ec, vim.split(e.newText, '\n', { plain = true }))
    elseif vim.b[buf].changedtick == it.rec.tick then
      -- A fix touching more than the flagged text: only safe on unchanged text.
      vim.lsp.util.apply_text_edits({ e }, buf, client.offset_encoding)
    else
      notify 'The text around this issue changed since the check; re-checking, try again in a moment.'
      schedule_recheck(buf, 0)
      return
    end
    drop(buf, it.id)
    schedule_recheck(buf, M.opts.fix_recheck_ms)
  elseif choice.kind == 'hide' then
    if not acts.hide then
      notify "This issue can't be ignored individually."
      return
    end
    drop(buf, it.id)
    client:exec_cmd(acts.hide, { bufnr = buf })
  elseif choice.kind == 'disable' then
    if not acts.disable then
      notify "This issue's rule can't be disabled."
      return
    end
    -- Clear every flag from that rule, in all documents of that language.
    local code, lang = it.rec.diag.code, ltex_language(buf)
    for b, recs in pairs(issues) do
      if vim.api.nvim_buf_is_valid(b) and ltex_language(b) == lang then
        for id, rec in pairs(recs) do
          if rec.diag.code == code then
            drop(b, id)
          end
        end
      end
    end
    client:exec_cmd(acts.disable, { bufnr = buf })
    notify(('Rule %s disabled for %s.'):format(tostring(code), lang))
  end
  last_choice = choice
  touch()
end

local function menu(buf, it)
  if not it then
    notify 'No grammar issue under the cursor (]g goes to the next one).'
    return
  end
  if not it.rec.actions then
    notify 'Fixes for this issue are still loading; try again in a moment.'
    return
  end
  local items = {}
  for i, f in ipairs(it.rec.actions.fixes) do
    table.insert(items, { label = ('%d  %s'):format(i, f.label), choice = { kind = 'fix', n = i } })
  end
  if it.rec.actions.hide then
    table.insert(items, { label = 'Ignore here', choice = { kind = 'hide' } })
  end
  if it.rec.actions.disable then
    table.insert(items, { label = ('Ignore this rule (%s)'):format(tostring(it.rec.diag.code)), choice = { kind = 'disable' } })
  end
  local id = it.id
  vim.ui.select(items, {
    prompt = it.rec.diag.message,
    format_item = function(x)
      return x.label
    end,
  }, function(x)
    if x then
      apply(buf, by_id(buf, id), x.choice)
    end
  end)
end

-- g= goes through 'operatorfunc' (g@l) so that `.` repeats it.
local from_mapping -- set by the g= mapping; nil when `.` replays it

function M.fix_map()
  from_mapping = { count = vim.v.count }
  vim.o.operatorfunc = "v:lua.require'custom.grammar'.fix_op"
  return 'g@l'
end

function M.fix_op()
  local buf = vim.api.nvim_get_current_buf()
  local it = issue_at_cursor(buf)
  if from_mapping then
    local count = from_mapping.count
    from_mapping = nil
    if count > 0 then
      apply(buf, it, { kind = 'fix', n = count })
    else
      menu(buf, it)
    end
  elseif last_choice then
    apply(buf, it, last_choice)
  end
end

-- ---------------------------------------------------------------------------
-- Keys inside checked documents
-- ---------------------------------------------------------------------------
local function set_keys(buf)
  local function o(desc)
    return { buffer = buf, desc = desc }
  end
  vim.keymap.set('n', ']g', function()
    M.next(vim.v.count1)
  end, o 'Next grammar issue')
  vim.keymap.set('n', '[g', function()
    M.prev(vim.v.count1)
  end, o 'Previous grammar issue')
  vim.keymap.set('n', ']G', M.last, o 'Last grammar issue')
  vim.keymap.set('n', '[G', M.first, o 'First grammar issue')
  vim.keymap.set('n', 'g=', M.fix_map, {
    buffer = buf,
    expr = true,
    desc = 'Fix grammar issue (Ng= applies fix N, . repeats)',
  })
end

local function del_keys(buf)
  for _, k in ipairs(KEYS) do
    pcall(vim.keymap.del, 'n', k, { buffer = buf })
  end
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------
stop = function(reason)
  if idle_timer then
    idle_timer:stop()
    idle_timer:close()
    idle_timer = nil
  end
  for buf in pairs(issues) do
    clear(buf)
  end
  for buf in pairs(recheck_timers) do
    cancel_recheck(buf)
  end
  local client = get_client()
  if client then
    client:stop()
    if reason then
      notify('Grammar checker stopped (' .. reason .. '). <leader>gc to check again.')
    end
  end
end

--- Check a buffer now; start the server first if it isn't running.
function M.check(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  if not M.opts.filetypes[vim.bo[buf].filetype] then
    notify('Grammar check is set up for Markdown and Typst only.', vim.log.levels.WARN)
    return
  end
  if vim.fn.executable(M.opts.cmd) == 0 then
    notify(
      M.opts.cmd .. ' not found. Install it with :MasonInstall ltex-ls-plus (or add it to ensure_installed).',
      vim.log.levels.ERROR
    )
    return
  end

  touch()
  pending_report[buf] = true
  local client = get_client()
  if client and client.attached_buffers[buf] then
    check_document(client, buf)
    return
  end
  if not client then
    notify 'Grammar: starting LTeX+ (first check takes ~10-15 s)...'
  end
  vim.lsp.start({
    name = NAME,
    cmd = { M.opts.cmd },
    cmd_env = { JAVA_OPTS = '-Xmx' .. M.opts.heap },
    settings = { ltex = settings_for(buf) },
    handlers = {
      ['workspace/configuration'] = on_configuration,
      ['textDocument/publishDiagnostics'] = function(err, result, ctx)
        vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
        local b = vim.uri_to_bufnr(result.uri)
        vim.schedule(function()
          on_publish(b)
        end)
      end,
    },
    commands = commands,
  }, {
    bufnr = buf,
    -- One server for every document, whatever its folder.
    reuse_client = function(c, config)
      return c.name == config.name
    end,
  })
end

--- Stop the server now.
function M.stop()
  if get_client() then
    stop 'stopped by hand'
  else
    notify 'Grammar checker is not running.'
  end
end

--- All issues of this document in the location list.
function M.list()
  local buf = vim.api.nvim_get_current_buf()
  if not attached(buf) then
    notify 'Grammar check is not running in this document: <leader>gc to start it.'
    return
  end
  local items = {}
  for _, it in ipairs(live(buf)) do
    table.insert(items, {
      bufnr = buf,
      lnum = it.sr + 1,
      col = it.sc + 1,
      end_lnum = it.er + 1,
      end_col = it.ec + 1,
      text = it.rec.diag.message,
    })
  end
  if #items == 0 then
    notify 'No grammar issues in this document.'
    return
  end
  vim.fn.setloclist(0, {}, ' ', { title = 'Grammar issues', items = items })
  vim.cmd 'lopen'
end

--- Called by writing_language.lua when a buffer's language changes.
function M.language_changed(buf)
  local client = attached(buf)
  if client then
    clear(buf) -- the old language's flags no longer apply
    pending_report[buf] = true
    touch()
    refresh(client)
  end
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend('force', M.opts, opts or {})
  vim.api.nvim_set_hl(0, 'GrammarIssue', { link = 'DiagnosticUnderlineInfo', default = true })
  local group = vim.api.nvim_create_augroup('writer-grammar', { clear = true })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not (client and client.name == NAME) then
        return
      end
      -- LTeX+'s own diagnostics stay out of sight (and out of ]d / <C-w>d):
      -- the tracked marks above are what you see, since they follow edits.
      vim.diagnostic.enable(false, { bufnr = args.buf, ns_id = vim.lsp.diagnostic.get_namespace(client.id) })
      set_keys(args.buf)
      sent_tick[args.buf] = vim.b[args.buf].changedtick -- didOpen sent this text
      if vim.bo[args.buf].filetype ~= 'markdown' then
        check_document(client, args.buf) -- 'manual' mode doesn't check on open
      end
    end,
  })

  vim.api.nvim_create_autocmd('LspDetach', {
    group = group,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not (client and client.name == NAME) then
        return
      end
      del_keys(args.buf)
      clear(args.buf)
      cancel_recheck(args.buf)
      sent_tick[args.buf] = nil
      vim.schedule(function()
        local c = get_client()
        if c and vim.tbl_isempty(c.attached_buffers) then
          stop() -- no checked documents left open
        end
      end)
    end,
  })

  -- Markdown: the server re-checks on save; that's the text it will check.
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    callback = function(args)
      if attached(args.buf) and vim.bo[args.buf].filetype == 'markdown' then
        sent_tick[args.buf] = vim.b[args.buf].changedtick
        touch()
      end
    end,
  })

  -- Edits: drop issues whose text you changed; Typst re-checks after a pause.
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = group,
    callback = function(args)
      if not attached(args.buf) then
        return
      end
      if issues[args.buf] then
        live(args.buf)
      end
      if vim.bo[args.buf].filetype ~= 'markdown' then
        schedule_recheck(args.buf, M.opts.typst_pause_ms)
      end
    end,
  })

  -- In documents that aren't being checked, say so instead of doing nothing.
  for _, k in ipairs(KEYS) do
    vim.keymap.set('n', k, function()
      notify 'Grammar check is not running in this document: <leader>gc to start it.'
    end, { desc = 'Grammar keys (start with <leader>gc)' })
  end

  vim.api.nvim_create_user_command('GrammarCheck', function()
    M.check()
  end, { desc = 'Check grammar of this document (LTeX+)' })
  vim.api.nvim_create_user_command('GrammarStop', function()
    M.stop()
  end, { desc = 'Stop the grammar checker (LTeX+)' })
  vim.api.nvim_create_user_command('GrammarList', function()
    M.list()
  end, { desc = 'List grammar issues in the location list' })
end

return M
