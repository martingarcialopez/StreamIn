# Translation review

A reviewer who isn't a developer goes through every on-screen string, in English
and Spanish, and edits the copy in a spreadsheet, trying each change in the app
in the simulator as they go. One command then writes their edits back to the
String Catalogs.

Everything lives in `scripts/translations/`:

```
scripts/translations/
├── translations.sh                — export, import, preview, test
├── translator-preview.sh          — the app in the simulator, with the workbook's edits
├── streamin-translations.numbers  — the workbook (gitignored, made by export)
└── lib/                           — translations.py and its tests, screens.json,
                                     numbers.applescript, requirements.txt, the venv
```

## The loop

1. **Export** the workbook:

   ```bash
   scripts/translations/translations.sh export
   ```

   It writes `scripts/translations/streamin-translations.numbers` (gitignored), next to the
   preview script; `--out` picks another path. It needs a Mac with Numbers. An existing workbook is never replaced, since it may hold a review in
   progress: import it first, or pass `--force`. The first run creates the tool's
   venv with the pinned `openpyxl`, and macOS asks once to let the terminal
   control Numbers.

2. **Review in Numbers.** Each sheet is a screen and each row a string. The
   reviewer edits the English and Spanish cells in place, leaves comments in
   Notes and saves with ⌘S. The first sheet explains this in Spanish. Hidden
   columns keep the exported text and the catalog each string comes from.

3. **Try the edits in the app** as often as they like:

   ```bash
   scripts/translations/translator-preview.sh es
   ```

   The app opens in the simulator in that language with the edits in
   `scripts/translations/streamin-translations.numbers`: saved ones, or what's on screen if
   the workbook is open in Numbers. Without the workbook it stops with an error.
   The catalogs aren't touched. The edits go into a copy of the built app's
   compiled strings, so a run takes a few seconds. The app is built only on the
   first run; pass `--build` after the code or the catalogs change (after an
   import, say). Other options: `en` for English, `--onboarding` to start from
   the first launch. An edit that would break the app (a changed placeholder) is
   left out and listed.

4. **Import** when the review is done. Check first, then write:

   ```bash
   scripts/translations/translations.sh import --dry-run
   ```

   ```bash
   scripts/translations/translations.sh import
   ```

   Both read `scripts/translations/streamin-translations.numbers` unless given another
   workbook. The report lists the changes, the rows to look at again and the
   reviewer's notes. Open a PR like any other copy change, then delete the
   workbook (or export a fresh one with `--force`). `translator-preview.sh es
   --build` shows the imported copy from the catalogs themselves.

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

## Numbers

Numbers can't save in `.xlsx`, so the tool reads and writes `.numbers` through
Numbers itself (`scripts/translations/lib/numbers.applescript`): `.xlsx` → `.numbers`
on export, `.numbers` → `.xlsx` on import and preview, in a `translations-tmp-…`
folder next to the workbook that's removed afterwards. A workbook open in Numbers
stays open. Numbers adds an "Export Summary" sheet to the `.xlsx`; the import
skips any sheet without a key column.

## Sheets are screens

`scripts/translations/lib/screens.json` lists each screen (one sheet) and the Swift
files that show its strings. Every key goes to the screen of the first file that
uses its symbol, in source order. Keys that no file uses are left out and listed
by the export. A new view that shows strings but isn't in `screens.json` makes the
export fail with the file's name: add it to its screen.

## Para quien revisa

Cada pestaña del libro es una pantalla de la app, en el orden en que se usa. Si
un texto se puede mejorar, cámbialo directamente en su celda, en inglés o en
español; si está bien, déjalo como está. «Notas» es para dudas y comentarios.
`%@` y `%lld` son huecos que la app rellena y tienen que seguir en el texto.
Para ver tus cambios en la app, sin necesidad de guardar (`en` para inglés):

```bash
scripts/translations/translator-preview.sh es
```

## Tests

```bash
scripts/translations/translations.sh test
```

They run in CI before the app build: export, edit, import and preview on a tiny
repo, and the real catalogs must serialize back byte for byte. The Numbers
conversion needs Numbers, so it's checked by hand.
