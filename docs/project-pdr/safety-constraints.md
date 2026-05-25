# Safety Constraints

## Filesystem Constraints

- Scan roots must be readable directories and cannot be inside protected system prefixes.
- Protected paths include `/System`, `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin`, `/etc`, and `/var/db`.
- Scan traversal skips hidden files at the directory API layer and ignores symlinks during size calculation.
- Scan results are capped per root to keep the MVP responsive and predictable.

## Cleanup Constraints

- Cleanup only operates on explicitly selected items.
- Nested selections are collapsed before cleanup so parent and child paths are not double-processed.
- Missing paths, protected paths, and symlinks are refused and returned as explicit cleanup results.
- Successful cleanup always uses Finder Trash so the user has an OS-level recovery path.

## UX Constraints

- Errors are surfaced as diagnostics or inline banners instead of interruptive crash paths.
- Homebrew support is optional; if `brew` is not installed, the app reports that state instead of assuming availability.
