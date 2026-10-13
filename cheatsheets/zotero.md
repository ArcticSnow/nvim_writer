# Zotero + Better BibTeX

Press `q` to close, `/` to search. `<leader>tH` switches sheets.

## How it fits together

1. Zotero (with the browser Connector) collects your papers.
2. Better BibTeX gives every item a citation key.
3. An auto-export keeps `refs.bib` in your Obsidian vault in sync.
4. This editor reads that file: `<leader>bb` cites, `<leader>bo` jumps back
   to Zotero.

## One-time setup

- Choose your key formula in Zotero > Settings > Better BibTeX > Citation
  Keys. The default is `auth.lower + shorttitle(3,3) + year`.
- Right-click your library or a collection > Export... > format
  **Better BibLaTeX** (or Better BibTeX) > tick **Keep updated** > save it as
  `refs.bib` in the vault.

## Gotchas

- **Keep updated only works while Zotero is running.** Items added while it
  is closed show up after you reopen it.
- **Unpinned keys can change** when you edit an item's title, author or
  year, or change the key formula. A changed key breaks `@key` in documents
  you already wrote. Once you start citing an item, right-click it > Better
  BibTeX > Pin BibTeX key.
- Zotero tags are exported as `keywords`, so `<leader>bb` can search them.
- BibLaTeX export uses `date` and `journaltitle`. Typst, Pandoc and this
  editor all read both flavors.

## Using the file

| Where | What to write |
|---|---|
| Markdown / Quarto front matter | `bibliography: refs.bib` |
| Typst, once in the document | `#bibliography("refs.bib")` |
| Typst, pick a style | `#bibliography("refs.bib", style: "apa")` |
| Typst, include uncited entries | `#bibliography("refs.bib", full: true)` |
| Typst, a citation in prose | `#cite(<key>, form: "prose")` |

## A Typst project outside the vault

Typst only reads files inside the project folder, and a path starting with
`/` means "from the project root", not from the root of the disk. So an
absolute path to the vault fails (tested). Link the file instead, once per
project, from inside the project folder:

````
ln -s ~/Documents/MF_vault/refs.bib refs.bib
````

The link lives inside the project, so Typst reads it, and the real file
keeps updating. Adjust the path if your vault is elsewhere.

## In this editor

| Key | Does |
|---|---|
| `<leader>bb` | search the library and insert a citation |
| `<leader>bz` | pick a different `.bib` file |
| `<leader>bp` | show author, year and title for the citation under the cursor |
| `<leader>bo` | open that item in Zotero |

`<leader>bb` searches key, authors, title, year, journal and tags. Type
several words in any order, or `'word` for an exact match (see the fzf
sheet). `<leader>bo` hands `zotero://select/items/bbt:KEY` to your system; if
nothing opens, try that link in a browser to see whether the problem is the
link or the editor.
