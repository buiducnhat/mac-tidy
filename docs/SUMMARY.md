# Documentation Summary

MacTidy is a local-first macOS cleanup utility built with SwiftUI and SwiftPM. It separates UI state from filesystem and Homebrew logic, then packages the app into an unsigned `.app` bundle with a custom script-based workflow.

## Agent Context Guide

Before planning or implementing, read this `docs/SUMMARY.md` file first. Load only the detail docs relevant to the current task, and prioritize `Code Standard` docs for implementation conventions. If docs conflict with code or user intent, use the available input/question before making broad changes.

## Architecture

System design, component interactions, data flows, deployment, and external integrations.

| File | Description |
| ---- | ----------- |
| [system-components.md](architecture/system-components.md) | Describes the SwiftPM target split, store graph, and service boundaries. |
| [user-flows.md](architecture/user-flows.md) | Maps the analyze, cleanup, and Homebrew interaction flows. |

## Codebase

Directory structure, entry points, API patterns, and key modules.

| File | Description |
| ---- | ----------- |
| [targets-and-directories.md](codebase/targets-and-directories.md) | Maps the top-level folders, targets, and startup files. |
| [ui-state-and-navigation.md](codebase/ui-state-and-navigation.md) | Explains how views, destinations, and stores are connected. |

## Code Standard

Conventions, naming rules, tech stack versions, and development workflows.

| File | Description |
| ---- | ----------- |
| [swift-patterns.md](code-standard/swift-patterns.md) | Project-specific Swift, Observation, and safety patterns. |
| [tooling-and-release.md](code-standard/tooling-and-release.md) | Build, verification, resource, and release workflow conventions. |

## Project PDR

Product goals, use cases, business rules, and constraints.

| File | Description |
| ---- | ----------- |
| [product-scope.md](project-pdr/product-scope.md) | Documents the current MVP scope and user-facing capabilities. |
| [safety-constraints.md](project-pdr/safety-constraints.md) | Captures the cleanup and filesystem constraints enforced by the app. |

## Other

Optional section for repository-specific docs outside the standard topic folders, such as dated brainstorms, plans, or deployment notes.

| File | Description |
| ---- | ----------- |
| [app icon asset](assets/mactidy-icon.png) | PNG copy of the generated app icon used in the README and repository presentation. |
| [archived plan summary](plans/archived/260523-1709-swiftui-cleaner-mvp/SUMMARY.md) | Archived implementation plan for the initial MVP buildout. |
| [archived execution report](plans/archived/260523-1709-swiftui-cleaner-mvp/EXECUTION-REPORT.md) | Archived execution notes from the MVP implementation run. |
| [phase 1 plan](plans/archived/260523-1709-swiftui-cleaner-mvp/phase-01-scaffold-swiftui-app-shell.md) | Archived app shell and startup implementation plan. |
| [phase 2 plan](plans/archived/260523-1709-swiftui-cleaner-mvp/phase-02-scan-core-and-analyze.md) | Archived scan-core and analyze workflow implementation plan. |
| [phase 3 plan](plans/archived/260523-1709-swiftui-cleaner-mvp/phase-03-clean-purge-installers-trash-flow.md) | Archived cleanup flow implementation plan. |
| [phase 4 plan](plans/archived/260523-1709-swiftui-cleaner-mvp/phase-04-safety-polish-tests-release-readiness.md) | Archived release-readiness and polish plan. |
| [visual plan rendering](plans/archived/260523-1709-swiftui-cleaner-mvp/visualize.html) | HTML rendering of the archived implementation plan. |
| [visual theme asset](plans/archived/260523-1709-swiftui-cleaner-mvp/visualize-assets/visualize-theme.css) | CSS theme used by the archived plan visualization. |
