# Tooling And Release

## Build And Verification

- Use SwiftPM as the source of truth; there is no Xcode project in the repo.
- `script/build_and_run.sh` is the default local run path and is also referenced by the Codex environment.
- `swift build`, `swift run MacTidyCoreTests`, and `script/build_and_run.sh --verify` are the expected verification commands.
- `swift test` is intentionally not part of the workflow in this workspace.

## Resources

- App bundle resources live under `Support/Resources/`.
- `script/build_and_run.sh` copies those resources into `dist/MacTidy.app/Contents/Resources`.
- App icons are maintained as both a 1024px source PNG and a generated `.icns`.

## Release Packaging

- `script/package_release.sh` is the release packaging entry point.
- Set `APP_VERSION` when building a tagged release so the bundle metadata and archive naming stay aligned.
- Release archives are written to `dist/releases/` and should remain out of git.
