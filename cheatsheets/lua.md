# Lua cheatsheet (for Neovim configs)

Press `q` to close, `/` to search. `<leader>tH` switches sheets.

## Basics

| Lua | Notes |
|---|---|
| `local x = 1` | always `local`; a bare assignment makes a global |
| `~=` | not equal (`!=` is a syntax error) |
| `..` | concatenate strings; `#s` and `#t` give the length |
| `nil` and `false` | the only falsy values: `0` and `""` are true |
| `t[1]` | arrays start at 1 |
| `a and b or c` | ternary-ish, but gives `c` whenever `b` is false or nil |
| `-- note`, `--[[ block ]]` | comments |
| `[[long string]]` | a multi-line string |

## Calling syntax you'll see everywhere

- `f 'text'` is `f('text')`, and `f { ... }` is `f({ ... })`. This only works
  for a single string or table argument: `require 'mini.pairs'`,
  `require('x').setup { ... }`.
- `obj:method(a)` is `obj.method(obj, a)`.
- `local function f() end` for named functions, `function() end` for
  callbacks.

## Tables and loops

```lua
local list = { 'a', 'b' }
local map = { key = 1, ['odd key'] = 2 }
for i, v in ipairs(list) do print(i, v) end  -- arrays, in order
for k, v in pairs(map) do print(k, v) end    -- any table, any order
table.insert(list, 'c')
```

## Patterns (not regex)

| Pattern | Meaning |
|---|---|
| `%` | the escape character, not backslash: `%.` `%-` `%%` |
| `%s %w %a %d` | space, alphanumeric, letter, digit (`%S` is the opposite) |
| `.` `*` `+` `-` `?` | any char; repeat 0+, 1+, 0+ lazily; optional |
| `^` `$` | start / end of the string |
| `(...)` | capture; an empty `()` captures the position |
| `%b{}` | a balanced pair of braces, nesting included |
| `s:find(p, 1, true)` | plain-text search, no patterns |
| `s:match(p)`, `s:gmatch(p)`, `s:gsub(p, r)` | extract, loop, replace |

`gsub` returns two values (text, count). Wrap it as `(s:gsub(p, r))` when you
only want the text.

## Neovim API essentials

- `vim.opt.wrap = true` (or `vim.o.wrap`) sets an option; `vim.bo[buf].x` and
  `vim.wo[win].x` are buffer and window options; `vim.g.x` a variable.
- `vim.keymap.set('n', '<leader>x', fn, { desc = '...', buffer = buf })`
- `vim.api.nvim_create_autocmd('FileType', { group = g, pattern = 'markdown',
  callback = fn })`, with `local g = vim.api.nvim_create_augroup('name',
  { clear = true })`
- `vim.api.nvim_create_user_command('Name', fn, {})`
- `vim.cmd 'colorscheme x'` or `vim.cmd.colorscheme 'x'` runs an Ex command.
- `vim.fn.expand('%:p')`, `vim.fn.stdpath('config')` call Vimscript functions.
- `vim.notify(msg, vim.log.levels.WARN)` shows a message.
- `vim.system({ 'cmd', 'arg' }, { text = true }, callback)` runs a program.
- `vim.schedule(fn)` and `vim.defer_fn(fn, ms)` run something later.
- `vim.tbl_deep_extend('force', a, b)`, `vim.list_extend(a, b)`,
  `vim.tbl_contains(t, v)`, `vim.split(s, '\n', { plain = true })`,
  `vim.trim(s)`, `vim.startswith(s, p)`.
- `vim.lsp.config('name', { settings = {} })`, then `vim.lsp.enable 'name'`.

## Gotchas that have bitten this config

- **Fast-event callbacks.** A callback from `vim.system` or libuv can't call
  `vim.fn.*` or most of `vim.api.*` (error E5560). Wrap it:
  `vim.system(cmd, opts, vim.schedule_wrap(function(res) ... end))`.
- **`vim.o.x` for a window option reads the current window.** The real global
  is `vim.api.nvim_get_option_value('x', { scope = 'global' })`.
- **`require` caches.** Editing a module file doesn't change a running
  session; restart Neovim.
- **Neovim embeds LuaJIT** (Lua 5.1 plus extras): no `//` division, no `&`
  or `|` operators (use `bit.band`), and `unpack`, not `table.unpack`.
  `goto` works.

## vim.pack (Neovim 0.12)

- `vim.pack.add({ { src = 'https://github.com/o/r', version = 'main' } }, {
  load = true })` installs and loads. `confirm = false` skips the prompt.
- `vim.pack.update({ 'name' })` opens a review buffer: `:write` applies the
  update, `:quit` discards it. Restart afterwards.
- `vim.pack.get()` lists what is installed.
- `vim.pack.del({ 'name' })` refuses while the plugin is active. Remove it
  from your config, restart, then delete it.

## Debugging

- `:lua =expr` prints a value, e.g. `:lua =vim.o.columns`.
- `:lua print(vim.inspect(t))` prints a table.
- `:messages` replays recent messages; `:checkhealth` runs the health checks.
- `:Inspect` shows the highlight and treesitter groups under the cursor.
- `:verbose map <leader>th` shows where a mapping was defined.
