# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`pgrind` is a native macOS SwiftUI app for studying problem sets (e.g. MIT OCW courses). Users capture problems as screenshots or webpage references, attempt them, and track difficulty over time. Built with Swift 5, SwiftUI, and SwiftData. Deployment target: **macOS 26.2**. There is no test target.

## Build & Run

Run the following commands to build, clean, run and debug the project:

```bash
# Build
xcodebuild -project pgrind.xcodeproj -scheme pgrind -configuration Debug \
    -derivedDataPath build build
# Build and run tests
xcodebuild -project pgrind.xcodeproj -scheme pgrind -configuration Debug \
    -derivedDataPath build test
# Clean
xcodebuild -project pgrind.xcodeproj -scheme pgrind clean
# Run
build/Build/Products/Debug/pgrind.app/Contents/MacOS/pgrind
# View debug logs (live stream)
log stream --predicate 'process == "pgrind"' --level debug
# View debug logs (after execution)
log show --predicate 'process == "pgrind"' --last 5m --info --debug
```

If the app crashes, crash reports land in ~/Library/Logs/DiagnosticReports/pgrind-*.ips.

After each change, build, run tests and run the project to make sure it compiles and executes cleanly, and check the logs for any warnings or errors.

New `.swift` files must be added to the Xcode target in `project.pbxproj` — creating a file on disk alone won't compile it.

## Workflow

Work directly on the `main` branch — this is preferred. Commit and push to `main` rather than creating feature branches, unless explicitly asked otherwise.

## Architecture

### Persistence (SwiftData)

The model container is constructed in `pgrind/pgrindApp.swift` and shared across all `WindowGroup`s via `.modelContainer(sharedModelContainer)`. Storage is on-disk and goes through `MigrationPlan` (`Migrations/PgrindMigrationPlan.swift`).

- **Staged migrations don't currently work in this repo.** The `SchemaVN` enums under `Migrations/` reference the *live* model classes (e.g. `StudyPlan.self`), not frozen historical copies. So when a `@Model` changes shape, every `SchemaVN` that lists it changes too — they all describe the same new shape. Adding a second versioned schema + a `MigrationStage` therefore crashes at launch with `NSInvalidArgumentException: 'Duplicate version checksums detected'`, because the versions hash identically.
- **For now, keep a single schema** (`schemas: [SchemaV1]`, `stages: []`, app builds `Schema(versionedSchema: SchemaV1.self)`) and let SwiftData's **automatic lightweight migration** absorb additive and relationship changes. Verified on 2026-06-20 swapping `StudyPlan.courses: [Course]` → `topics: [Topic]`: it migrates cleanly but drops the changed relationship's existing rows (acceptable for dev data).
- Enabling true staged migrations would first require freezing each historical model as a nested type inside its `SchemaVN` (the canonical SwiftData pattern) — a repo-wide refactor that has never been done. Until then, do **not** add `SchemaV2`/`MigrationStage`.
- Keep the `models:` list in `SchemaV1.swift` in sync with the persistent types. Note: `Deck` was added recently but is not yet listed — adding a new persistent type still requires updating that list.

### Domain model

Two parallel hierarchies own `ProblemSet`s:

- `Course` → `ProblemSet` → `Problem` (the canonical taxonomy: a course owns its problem sets).
- `Deck` → `ProblemSet` (curated cross-course study collections, e.g. "Summer 2026 exams").

`Problem` is an abstract-ish base `@Model` with concrete subclasses `ImageProblem` (screenshot question + optional solution image, stored with `.externalStorage`) and `WebpageProblem`. Subclasses are filtered out of `ProblemSet.problems` via `compactMap { $0 as? ImageProblem }`-style accessors. New `Problem` subclasses must be registered in the schema and `modalProblemKind` updated.

`Attempt` records a `Difficulty` (see `Models/ValueObjects/Difficulty.swift`) per attempt; `Problem.currentDifficulty` and `lastAttempted` derive from the latest attempt.

`Problem` is annotated `@MainActor` — most computed properties that traverse relationships (e.g. `ProblemSet.imageProblems`, `modalProblemKind`) are also `@MainActor`. Treat the model graph as main-actor-only when calling these.

### UI structure

- `ContentView` → `BrowseView` is the primary window. `BrowseView` is a `NavigationSplitView` whose sidebar lists `Course`s and `Deck`s and whose detail pane switches between `ProblemsGalleryView` (thumbnails) and `ProblemsHeatmapView` based on a local `ViewMode`.
- A second `WindowGroup(id: "create-problem", for: PersistentIdentifier?.self)` hosts `CreateProblemWizard` as a separate window, opened via `@Environment(\.openWindow)`. The wizard under `Views/CreateProblemWizard/Steps/` is a step-based flow (Select/Create Course → Select/Create ProblemSet → Select Kind → image or webpage capture).
- `CreateDeckSheet` is a sheet for assembling a `Deck` from existing `ProblemSet`s.
- Studying lives in `StudyView` / `StudyProblemView` / `RecordAttemptView`.

### Screenshot capture

`Utils/Screenshotter.swift` uses `ScreenCaptureKit` to grab problem images for `ImageProblem`. PNG conversion lives in `Extensions/CGImage+PNG.swift`. `Components/ExpandableImageView` renders captured images with pinch-to-zoom.
