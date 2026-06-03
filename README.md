# MacTidy

![MacTidy icon](docs/assets/mactidy-icon.png)

MacTidy is a local macOS SwiftUI cleaner MVP. It scans readable, non-protected user-selected locations, labels cleanup candidates, and moves explicitly selected items to Finder Trash. The app also includes a Homebrew workspace for reviewing installed packages, outdated packages, taps, and maintenance commands.

## Documentation

- [Documentation summary](docs/SUMMARY.md)

## Run

```bash
script/build_and_run.sh
```

The Codex app Run action is wired to the same script through `.codex/environments/environment.toml`.

## Verify

```bash
swift build
swift run MacTidyCoreTests
script/build_and_run.sh --verify
```

`swift test` is not used in this workspace because the local Swift toolchain does not expose `XCTest` or Swift Testing modules.

## Package A Release

```bash
APP_VERSION=0.1.1 script/package_release.sh
```

This creates `dist/MacTidy.app` and a zipped release artifact in `dist/releases/`.

If macOS blocks the packaged app on first launch after moving it into `/Applications`, clear the quarantine flag:

```bash
xattr -c /Applications/MacTidy.app
```

## Safety

- No sudo, privileged helper, background agent, or permanent delete.
- Protected system paths are refused.
- Symlinks are skipped during scans and refused during cleanup.
- Cleanup collapses selected child paths under selected parents.
- Cleanup moves items to Trash after confirmation.
