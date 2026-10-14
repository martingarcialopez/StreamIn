---
name: pr-screenshots
description: Put before/after screenshots of the screens a branch changed or added into its PR description — render the Xcode previews on the branch and on main, publish them, and write a compact side-by-side table. Use from ship-phase after the PR is opened, again when a later push changes a view, or when Martín asks for screenshots on a PR.
argument-hint: [PR number]
---

# Screenshots in the PR description

The reviewer sees what a UI change looks like without checking the branch out.
Rendered Xcode previews (`RenderPreview`), never the live app: they're fast,
need no API key and show the preview's stub data.

Run it in the branch's worktree with **everything committed** (step 3 switches
commits). Shell style is the worktree one: one plain command per call, literal
paths. Images go in `.build/pr-screenshots/` (gitignored); start with it empty
(`rm -rf .build/pr-screenshots`, then `mkdir -p .build/pr-screenshots`).

## 1. Pick the screens

`git diff --name-only origin/main...HEAD -- Packages StreamIn/App` (after
`git fetch origin main`), keeping Swift files under `Sources/` of a `*Feature`
package, `DesignSystem`, and `StreamIn/App`.

- A changed or new file with `#Preview`s: its previews.
- A changed view, subview or view model without one: the preview of the screen
  that shows it (e.g. `WatchlistToggleButton` → a `DetailsView` preview).
- At most 4 previews per file: the ones that show the change. Name the skipped
  ones in your reply.
- No view touched (tests, view-model logic with no visible effect, tooling):
  stop and say so. The PR has no Screenshots section.

## 2. After: render on the branch

- Use this worktree's Xcode window (`XcodeListWindows`, match the path). If it
  isn't open: `open -g -a Xcode <worktree>/StreamIn.xcodeproj`.
- `RenderPreview` per preview: `sourceFilePath` is the path in Xcode's
  navigator (`DetailsFeature/Sources/DetailsFeature/DetailsView.swift`,
  `StreamIn/App/RootView.swift`), `previewDefinitionIndexInFile` the zero-based
  `#Preview` index. A first render can fail with "cannot find
  'GeneratedSecrets'" while the Run Script races the compiler; render again.
- **Look at each snapshot.** A spinner or an empty loading frame means `.task`
  hadn't finished: render again.
- Copy the result's `previewSnapshotPath` to
  `.build/pr-screenshots/<file>-<preview>-after.png`, lowercase with dashes
  (`detailsview-available-after.png`). The script rejects other characters.
- A preview that fails to render is listed in the table as not rendered, with
  the reason. Never drop it silently.

## 3. Before: render on main

Only for previews whose file exists on main; the rest are new screens.

1. `git merge-base origin/main HEAD` → `<base>`.
2. Opening the project can make Xcode re-sort `project.pbxproj`:
   `git restore StreamIn.xcodeproj/project.pbxproj`. Then `git status --short`
   must be empty.
3. `git switch --detach <base>`. Same worktree, same Xcode window: no second
   indexed copy.
4. Render the same previews, matched by `#Preview("name")`, falling back to
   the index. A preview that doesn't exist on main is new. Save as `…-before.png`.
5. `git restore StreamIn.xcodeproj/project.pbxproj` if it changed, then
   `git switch <branch>`. **Always switch back**, even when a render failed,
   and confirm with `git status --short --branch`.

## 4. Publish

```bash
scripts/publish-screenshots.sh <branch-name> .build/pr-screenshots/<a>.png .build/pr-screenshots/<b>.png …
```

The images go to the `pr-screenshots` branch under a folder named after the
branch, scaled to 800 px. It prints `<file>\t<url>` per image. The URLs name the
commit, so publishing again never changes an older PR's pictures. It never
touches the checkout, its branch or its index.

## 5. Write the section

Compact and side by side, so the screenshots don't take over the description.
An HTML table, one row per screen, every image `width="180"`:

```html
<table>
  <tr><th></th><th>Before (main)</th><th>After</th></tr>
  <tr><td valign="top"><sub>Details<br>Available</sub></td>
      <td><img src="<before url>" width="180"></td>
      <td><img src="<after url>" width="180"></td></tr>
  <tr><td valign="top"><sub>Watchlist<br>Empty <b>(new)</b></sub></td>
      <td align="center"><sub>new</sub></td>
      <td><img src="<after url>" width="180"></td></tr>
  <tr><td valign="top"><sub>Search<br>Results</sub></td>
      <td colspan="2"><sub>Not rendered: the preview doesn't build in preview mode.</sub></td></tr>
</table>
```

- More than 3 screens: the first 3 rows in the table, the rest in a second
  table inside `<details><summary>N more screens</summary> … </details>`.
- End with `<sub>Rendered Xcode previews (stub data), not the live app.</sub>`

The section goes between the template's markers, under `## Screenshots`:

```markdown
## Screenshots

<!-- screenshots:start -->
<table>…</table>
<sub>Rendered Xcode previews (stub data), not the live app.</sub>
<!-- screenshots:end -->
```

- **With a PR:** `gh pr view <n> --json body --jq .body`, write it to
  `.build/pr-screenshots/body.md` with the Write tool, replace what's between
  the markers (or add the section before `## Notes for reviewers` when they're
  missing), then `gh pr edit <n> --body-file .build/pr-screenshots/body.md`.
  A re-run replaces the section; it never adds a second one.
- **Without a PR:** give Martín the section to paste.

Reply with how many screens were rendered, which were skipped or failed, and
the PR link.
