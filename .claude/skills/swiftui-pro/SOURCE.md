# Source

`swiftui-pro` by Paul Hudson, vendored unmodified from
[twostraws/SwiftUI-Agent-Skill](https://github.com/twostraws/SwiftUI-Agent-Skill)
under the MIT license (see `LICENSE`).

- **Version:** 1.1, commit `be297ff80d` (Apr 20, 2026): `swiftui-pro/SKILL.md` and
  `swiftui-pro/references/`. The repository's plugin wrapper, assets and Codex
  config aren't needed here.
- **Why it's in the repo:** so `ios-reviewer` can apply it everywhere it runs,
  including GitHub Actions, and so its version is pinned (#51).
- **Upgrading:** v2.0.0 (Oct 7, 2026) targets Xcode 27.2. StreamIn builds with
  Xcode 26.6 for iOS 26, so upgrade together with the toolchain, not before.
  Replace these files from the new tag and update this note.
