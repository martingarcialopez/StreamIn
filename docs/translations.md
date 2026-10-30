# Translation review

A reviewer who isn't a developer goes through every on-screen string, in English
and Spanish, and edits the copy in a spreadsheet, with the app running in the
simulator next to them. One command then writes their edits back to the String
Catalogs.

## The loop

1. **Export** the workbook:

   ```bash
   scripts/translations.sh export
   ```

   It writes `build/translations/StreamIn-textos-<date>.xlsx` (`--out` to choose
   the path; the workbook is never committed). The first run creates the tool's
   venv with the pinned `openpyxl`.

2. **Share it.** It opens in Excel, Numbers or Google Sheets; it must come back
   as `.xlsx`. Each sheet is a screen, and each row a string: the reviewer edits
   the English and Spanish cells in place and leaves comments in Notes. The first
   sheet, in Spanish, explains this. Hidden columns keep the exported text and the
   catalog each string comes from.

3. **Open the app** next to them:

   ```bash
   scripts/translator-preview.sh es
   ```

   `en` for English, `--onboarding` to start from the first launch, `--no-build`
   to relaunch the last build in the other language.

4. **Import** the returned workbook. Check first, then write:

   ```bash
   scripts/translations.sh import ~/Downloads/StreamIn-textos.xlsx --dry-run
   ```

   ```bash
   scripts/translations.sh import ~/Downloads/StreamIn-textos.xlsx
   ```

   The report lists the changes, the rows to look at again and the reviewer's
   notes. Then run `scripts/translator-preview.sh es` again so the reviewer can
   see the new copy, and open a PR like any other copy change.

## What the import checks

A cell counts as edited when it differs from its hidden original.

- **Placeholders.** An edit must keep the current text's variables: `%@` and
  `%lld` may move, and `%1$@ %2$lld` equals `%@ %lld`, but none can be added,
  dropped or change type. One such error, an emptied cell or a key that no longer
  exists, and nothing is written; the report names the sheet and row.
- **Stale rows.** If a string changed in the code since the export, its edit is
  skipped and listed, so a later change is never overwritten with a review of the
  old text.
- **Length.** An edit much longer than the current text is applied but flagged:
  check it on screen, buttons and tabs have little room.
- **Plurals.** Keys with plural forms or substitutions don't fit one cell: the
  export leaves them out and lists them, to be edited in Xcode.
- **Style.** Catalogs keep their JSON style, so the diff shows only the changed
  values, and package symbols are regenerated.

## Sheets are screens

`scripts/translations/screens.json` lists each screen (one sheet) and the Swift
files that show its strings. Every key goes to the screen of the first file that
uses its symbol, in source order. Keys that no file uses are left out and listed
by the export. A new view that shows strings but isn't in `screens.json` makes the
export fail with the file's name: add it to its screen.

## Para quien revisa

Cada pestaña del libro es una pantalla de la app, en el orden en que se usa. Si
un texto se puede mejorar, cámbialo directamente en su celda, en inglés o en
español; si está bien, déjalo como está. «Notas» es para dudas y comentarios.
`%@` y `%lld` son huecos que la app rellena y tienen que seguir en el texto. La
primera pestaña del libro lo explica con más detalle.

## Tests

```bash
scripts/translations.sh test
```

They run in CI before the app build: export, edit, import on a tiny repo, and the
real catalogs must serialize back byte for byte.
