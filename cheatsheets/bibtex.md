# BibTeX cheatsheet

Press `q` to close, `/` to search. `<leader>tH` switches sheets.

## An entry

````
@article{doe2020snow,
  author  = {Doe, Jane and Roe, Richard},
  title   = {Snow {Albedo} in the {Alps}},
  journal = {The Cryosphere},
  year    = {2020},
  volume  = {14},
  pages   = {101--120},
  doi     = {10.5194/tc-14-101-2020},
}
````

The type comes after `@`, then `{key,`, then one `field = {value},` per line.
The key is what you cite: `@doe2020snow`.

## Entry types

| Type | Use for | Needs |
|---|---|---|
| `@article` | journal article | author, title, journal, year |
| `@book` | a whole book | author or editor, title, publisher, year |
| `@inproceedings` | conference paper | author, title, booktitle, year |
| `@incollection` | chapter in an edited book | author, title, booktitle, publisher, year |
| `@phdthesis` | PhD thesis | author, title, school, year |
| `@techreport` | report | author, title, institution, year |
| `@misc` | web page, dataset, software | nothing required |

## Writing values

| You write | Meaning |
|---|---|
| `{Doe, Jane and Roe, Richard}` | `Last, First`, people separated by `and` |
| `{Albedo}`, `{NASA}` | braces protect capitalization |
| `{{Whole Title Kept}}` | double braces protect the entire title |
| `{101--120}` | a page range uses two hyphens |
| `{...}` or `"..."` | a value goes in braces or quotes |
| `{\'e}`, `{\"u}` | LaTeX accents; plain UTF-8 (é, ü) works too |
| `@string{gj = "J. Glaciol."}` | a macro; then write `journal = gj`, no braces |

`and others` becomes "et al." in classic BibTeX styles, but Typst prints the
word "others" (tested), so list every author if you cite from Typst.

## BibTeX vs BibLaTeX field names

| BibTeX | BibLaTeX |
|---|---|
| `journal` | `journaltitle` |
| `year` (and `month`) | `date = {2020-04-01}` |
| `address` | `location` |
| `school` | `institution` |

Typst, Pandoc and this editor read both. In Zotero it is the export format:
"Better BibTeX" or "Better BibLaTeX".

## What the finder (`<leader>bb`) reads

- It searches key, authors, title, year, journal and keywords (Zotero tags).
- `year`, or if that is missing, the first four digits of `date`.
- Values must be in `{...}` or `"..."`. A bare `year = 2021` is not read, so
  the preview shows `n.d.`; `journal = gj` with an `@string` macro is not
  read either. Better BibTeX always writes braces, so exports are fine.
- Nested braces are fine: `{{Arctic}} glaciers` shows as "Arctic glaciers".
- The hover preview reads like `Doe & Roe (2020). Title *Journal*.`, and
  shows `Doe et al.` for three or more authors.
