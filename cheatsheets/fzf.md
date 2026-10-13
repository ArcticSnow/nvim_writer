# Fuzzy search (fzf) — quick guide

## The basics

- Type letters and they match **in order**, but not necessarily together — fuzzy by default.
- A **space** means AND: every word has to match somewhere, in any order.
- Case-insensitive, unless you type an uppercase letter — that switches that search to case-sensitive ("smart case").

## Syntax

| Type this | Matches |
|---|---|
| `word` | fuzzy — letters of "word" appear in order, not necessarily together |
| `'word` | **exact** — "word" appears as a literal substring |
| `^word` | line **starts** with "word" |
| `word$` | line **ends** with "word" |
| `!word` | line does **not** contain "word" (fuzzy) |
| `!'word` | line does **not** contain "word" (exact) |
| `a b` | both "a" **and** "b" must match, any order |
| `a \| b` | either "a" **or** "b" |

Combine freely: `'snow !'2019 .pdf$` → exact "snow", not containing exact "2019", ending in ".pdf".

## Fuzzy vs. exact — when to reach for which

**Fuzzy** (the default) is great when you half-remember the spelling, or you're
searching something short like a filename or a function name — a few
scattered letters in the right order is usually enough to find it.

**Exact** (`'word`) is better whenever fuzzy starts feeling *too* loose —
short or common words (surnames, years, single-syllable terms) can fuzzy-match
all kinds of unrelated things once the searchable text gets long. Bibliography
search is the clearest example: prefixing each word with `'` cuts straight to
"contains this exact word," no noise.

## In this config

| Keymap | Picker | Worth knowing |
|---|---|---|
| `<leader>ff` | Find files | Fuzzy is usually fine — short queries, small search space |
| `<leader>fg` | Live grep | Fuzzy is usually fine |
| `<leader>bb` | Insert citation | Try `'word` prefixes here first if results feel noisy — see below |

## If a search feels "too fuzzy"

Prefix every word with `'` for that one search:

```
'snow 'albedo
```

Both terms now have to appear as literal substrings, still combined with AND
— this is usually the fastest fix when fuzzy matching starts surfacing
things that don't really belong.
