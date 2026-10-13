# Markdown cheatsheet

Press `q` to close, `/` to search. `<leader>tH` switches sheets.

## Syntax

| You type | You get |
|---|---|
| `# H1`, `## H2`, `### H3` | headings |
| `**bold**` | bold |
| `*italic*` or `_italic_` | italic |
| `~~strike~~` | strikethrough (extension) |
| `` `code` `` | inline code |
| `[text](url)` | link |
| `![alt](path.png)` | image |
| `> quote` | blockquote |
| `---` | horizontal rule |
| `- item` / `1. item` | bullet / numbered list |
| `- [ ] task` / `- [x] done` | task list (extension) |
| `text[^1]` and `[^1]: the note` | footnote (extension) |
| `\*` | a literal asterisk (backslash escapes) |

"Extension" means Pandoc and GitHub support it, but original Markdown doesn't.

A fenced code block, with the language after the opening fence:

````
```python
print("hello")
```
````

A table; colons in the divider row set alignment:

````
| Left | Centered | Right |
|:-----|:--------:|------:|
| a    |    b     |     c |
````

## Citations (Pandoc / Quarto style, what `<leader>bb` inserts)

| You type | You get (author-date style) |
|---|---|
| `[@key]` | (Doe 2020) |
| `[@key, p. 4]` | (Doe 2020, p. 4) |
| `[@a; @b]` | (Doe 2020; Roe 2019) |
| `@key` | Doe (2020), inside a sentence |
| `[-@key]` | (2020), author suppressed |

These turn into real citations when Pandoc or Quarto processes the file; in
the editor they stay as plain text. The file needs front matter like this:

````
---
title: My draft
lang: fr
bibliography: refs.bib
---
````

`lang: fr` also switches this editor's spell checker to French.

## Editing (mini.surround and mini.ai)

| Keys | Result |
|---|---|
| `saiw*` | `word` becomes `*word*`; run it twice for `**word**` |
| `viwsa*` | the same, from a visual selection |
| ``viwsa` `` | wrap the selection in backticks (inline code) |
| `sd"` | delete the surrounding quotes |
| `sr"'` | replace `"` with `'` |
| `di"`, `da)` | delete inside quotes, delete around parentheses |
| `dix` | delete the contents of a fenced code block (the fence needs a language) |

## Spelling and grammar

| Keys | Does |
|---|---|
| `]s` / `[s` | next / previous misspelling |
| `z=` | spelling suggestions |
| `zg` | add the word to your dictionary |
| `]d` / `[d` | next / previous grammar hint (Harper) |
| `gra` | apply the suggestion |
| `<leader>zl` | switch between English and French |

## Other keys in this config

| Key | Does |
|---|---|
| `<leader>bb` | insert a citation |
| `<leader>bp` | preview the citation under the cursor (also shows on hover) |
| `<leader>bo` | open the citation in Zotero |
| `<leader>to` | outline panel (your headings) |
| `<leader>zz` | focus mode |
| `<leader>zt` | toggle smart typography |

Smart typography, when on: `--` becomes an en dash, a third `-` makes an em
dash, `...` becomes an ellipsis, and quotes turn curly. It is skipped inside
code.
