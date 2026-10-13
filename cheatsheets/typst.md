# Typst cheatsheet

Press `q` to close, `/` to search. `<leader>tH` switches to another sheet.

## Three ideas first

- `#` drops from markup into code: `#let x = 5`, then `Hello #x`
- `#set` changes a default from that point on: `#set text(size: 11pt)`
- `#show` rewrites how something renders: `#show heading: set text(fill: blue)`
- `[...]` is a block of markup passed to a function: `caption: [Some text]`

## Markup

| Typst | Markdown | LaTeX |
|---|---|---|
| `= H1`, `== H2` | `# H1`, `## H2` | `\section{}` |
| `*bold*` | `**bold**` | `\textbf{}` |
| `_italic_` | `*italic*` | `\textit{}` |
| `- item` | `- item` | `\item` in itemize |
| `+ item` | `1. item` | `\item` in enumerate |
| `#link("url")[text]` | `[text](url)` | `\href{url}{text}` |
| `` `code` `` | `` `code` `` | `\texttt{}` |
| `// comment` | (none) | `% comment` |
| `\` at end of line | `\` or two spaces | `\\` |
| `#footnote[text]` | (not standard) | `\footnote{}` |

## Math

| Typst | LaTeX |
|---|---|
| `$x^2$` inline | `$x^2$` |
| `$ x^2 $` display (note the spaces) | `\[ x^2 \]` |
| `a/b` | `\frac{a}{b}` |
| `sum_(i=0)^n` | `\sum_{i=0}^{n}` |
| `x_(i+1)` | `x_{i+1}` |
| `alpha`, `beta` | `\alpha`, `\beta` |
| `"if"` | `\text{if}` |

Greek letters and functions are plain names, and parentheses group
sub/superscripts instead of braces.

## Figures, tables, citations

- `#image("f.png")` inserts an image
- `#figure(image("f.png"), caption: [Text])` numbered, captioned figure
- `#figure(...) <fig-x>` then `@fig-x` labels it and cross-references it
- `#table(columns: 2, [a], [b], [1], [2])` cells are `[...]`, filled row by row
- `@key` cites a reference; needs `#bibliography("refs.bib")` once in the file
- `@key[p. 4]` cites with a page

`@name` resolves to a label if one exists, otherwise to a bibliography key.

## Page and text setup

- `#set page(margin: 2.5cm, numbering: "1")` margins and page numbers
- `#set text(font: "New Computer Modern", size: 11pt, lang: "en")` font and size
- `#set par(justify: true)` justified paragraphs
- `#set heading(numbering: "1.1")` numbered headings
- `#outline()` table of contents
- `#pagebreak()` new page

`lang: "fr"` also switches this editor's spell checker to French.

## Scripting

- `#let name = "x"` variable
- `#let f(a, b) = [#a and #b]` function
- `#for i in range(3) [Item #i ]` loop
- `#if x > 1 [big] else [small]` conditional

## Keys in this config

| Key | Does |
|---|---|
| `<leader>tp` | live preview in the browser |
| `<leader>tv` | open the compiled PDF |
| `<leader>tc` | force a compile |
| `<leader>tm` | insert a template |
| `<leader>to` | outline panel |
| `<leader>bb` | insert a citation |
| `<leader>bo` | open the citation in Zotero |
| `<leader>zz` | focus mode |
| `<leader>zl` | switch writing language (en/fr) |
| `<leader>th` | this cheatsheet |
