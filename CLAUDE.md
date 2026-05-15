# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`pgrind` is a native macOS SwiftUI app for studying problem sets (e.g. MIT OCW courses). Users capture problems as screenshots or webpage references, attempt them, and track difficulty over time. Built with Swift 5, SwiftUI, and SwiftData. Deployment target: **macOS 26.2**. There is no test target.

## Build & Run

Run the following commands to build, clean, run and debug the project:

```sh
# Build
xcodebuild -project pgrind.xcodeproj -scheme pgrind -configuration Debug \
    -derivedDataPath build build

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

After each change, build and run the project to make sure it compiles and executes cleanly, and check the logs for any warnings or errors.

New `.swift` files must be added to the Xcode target in `project.pbxproj` — creating a file on disk alone won't compile it.

## Architecture

### Persistence (SwiftData)

The model container is constructed in `pgrind/pgrindApp.swift` and shared across all `WindowGroup`s via `.modelContainer(sharedModelContainer)`. Storage is on-disk and uses a versioned migration plan.

- `Migrations/PgrindMigrationPlan.swift` lists schema versions and stages. When the persistent model graph changes, **add a new `SchemaVN`** under `Migrations/` and append a `MigrationStage` (lightweight when possible). Do not edit historical schema enums.
- The `schema:` array in `pgrindApp.swift` and the `models:` list in the latest `SchemaVN.swift` should be kept in sync. Note: `Deck` was added recently but is not yet listed in either — adding a new persistent type requires updating both plus a new schema version.

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
