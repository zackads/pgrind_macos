//
//  ProblemInspectorView.swift
//  pgrind
//
//  Created by Zack Adlington on 21/02/2026.
//

import SwiftData
import SwiftUI

struct ProblemInspectorView: View {
    @Environment(\.modelContext) private var modelContext
    let problem: ImageProblem

    @State var solutionImagesData: [Data] = []
    @State var editing: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: iconSystemName)
                    .imageScale(.large)
                Text(titleText)
                    .font(.headline)
            }

            Text("Created \(problem.createdDate.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let lastAttempted = problem.lastAttempted {
                Text("Last attempted on \(lastAttempted.formatted(date: .abbreviated, time: .shortened))")
            } else {
                Text("Not attempted")
            }

            Divider()

            imageProblemInspector(problem)

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var iconSystemName: String {
        return "photo"
    }

    private var titleText: String {
        return "Problem"
    }

    private func imageProblemInspector(_ imageProblem: ImageProblem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if let img = NSImage(data: imageProblem.questionImage) {
                    ExpandableImageView(image: img)
                } else {
                    ContentUnavailableView("Missing question image", systemImage: "photo")
                }
            }
            .frame(maxWidth: .infinity)

            Divider()

            Group {
                // Always show existing solution image if present
                if let data = imageProblem.solutionImage, let img = NSImage(data: data) {
                    ExpandableImageView(image: img)
                }

                // Show capture/editor UI when there is no existing solution, or when editing has begun
                if imageProblem.solutionImage == nil || editing || !solutionImagesData.isEmpty {
                    if !solutionImagesData.isEmpty {
                        VStack(spacing: 12) {
                            PiledImagesView(imagesData: solutionImagesData)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            HStack {
                                Button {
                                    Task { @MainActor in
                                        if let newData = await Screenshotter.takeScreenshot() {
                                            solutionImagesData.append(newData)
                                            editing = true
                                        }
                                    }
                                } label: {
                                    Label("Add another screenshot", systemImage: "plus")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)

                                Button(role: .destructive) {
                                    solutionImagesData.removeAll()
                                } label: {
                                    Label("Clear", systemImage: "trash")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                        }
                    } else {
                        Button {
                            Task { @MainActor in
                                if let newData = await Screenshotter.takeScreenshot() {
                                    solutionImagesData.append(newData)
                                    editing = true
                                }
                            }
                        } label: {
                            Label(
                                imageProblem.solutionImage == nil ? "Take a screenshot" : "Add a screenshot",
                                systemImage: "camera.viewfinder"
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            if editing {
                HStack(spacing: 12) {
                    Button {
                        // Merge existing solution image (if any) with new screenshots, top-to-bottom
                        var imagesToMerge: [Data] = []
                        if let existing = imageProblem.solutionImage {
                            imagesToMerge.append(existing)
                        }
                        imagesToMerge.append(contentsOf: solutionImagesData)

                        if let mergedSolution = Screenshotter.mergeImagesVertically(from: imagesToMerge) {
                            imageProblem.solutionImage = mergedSolution
                        }

                        do {
                            try modelContext.save()
                            editing = false
                            solutionImagesData = []
                        } catch {
                            print("Failed to save model context: \(error)")
                        }
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .cancel) {
                        // Discard in-progress edits
                        editing = false
                        solutionImagesData = []
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                    .buttonStyle(.bordered)
                }
            }

            statsSection
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stats")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if problem.lastAttempted != nil {
                Text("Attempts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                AttemptsHeatmap(attempts: problem.attempts, onSelect: { _ in })
            } else {
                Text("Not attempted")
            }
        }
    }
}

private struct AttemptsHeatmap: View {
    let attempts: [Attempt]
    let onSelect: (Attempt) -> Void

    /// Adaptive grid: cells at least 44pt wide, growing as space allows
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 20, maximum: 20), spacing: 8, alignment: .center)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(attempts) { attempt in
                Button {
                    onSelect(attempt)
                } label: {
                    Rectangle()
                        .fill(color(for: attempt.difficulty))
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .accessibilityHint("Open attempt details")
                        .help(attempt.createdDate.formatted(date: .abbreviated, time: .shortened))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func color(for difficulty: Difficulty) -> Color {
        switch difficulty {
        case .notAttempted:
            return Color.gray.opacity(0.7)
        case .easy:
            return Color.green.opacity(0.7)
        case .medium:
            return Color.orange.opacity(0.7)
        case .hard:
            return Color.red.opacity(0.7)
        }
    }
}

#Preview {
    // In-memory container so relationships behave like the real app.
    let container: ModelContainer
    do {
        container = try ModelContainer(
            for: Course.self, ProblemSet.self, ImageProblem.self, Attempt.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }

    let context = container.mainContext

    let course = Course(title: "Calculus", summary: "Learn Newton's method", hyperlink: "example.com")
    let problemSet = ProblemSet(course: course, name: "Prereqs")
    let problem = ImageProblem(problemSet: problemSet, questionImage: Data(), solutionImage: Data(), createdDate: Date.now)

    // Insert the graph
    context.insert(course)
    context.insert(problemSet)
    context.insert(problem)

    // Create attempts *for this problem*
    let attempts: [Attempt] = [
        Attempt(problem: problem, difficulty: .hard),
        Attempt(problem: problem, difficulty: .medium),
        Attempt(problem: problem, difficulty: .easy)
    ]
    attempts.forEach(context.insert)

    try? context.save()

    return ProblemInspectorView(problem: problem)
        .modelContainer(container)
}
