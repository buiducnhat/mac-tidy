# Product Scope

## Current MVP Goals

- Let a user review large or stale items in safe, readable locations they can already access.
- Offer focused cleanup modules for general cleanup, purge-style artifacts, and installer leftovers.
- Keep deletion reversible by using Finder Trash instead of permanent removal.
- Provide a secondary Homebrew workspace for package inspection and maintenance commands.

## Primary Use Cases

- Scan common user folders and identify the largest items worth review.
- Review cleanup candidates by risk level before selecting anything.
- Move explicitly selected candidates to Trash.
- Search for Homebrew packages and review installed, outdated, or tapped content.
- Run Homebrew utility commands from a desktop UI instead of Terminal.

## Explicit Non-Goals In This Repo

- No privileged cleanup or system-level maintenance.
- No background daemon, launch agent, or scheduled cleanup.
- No automatic deletion without explicit selection.
- No permanent delete workflow.
