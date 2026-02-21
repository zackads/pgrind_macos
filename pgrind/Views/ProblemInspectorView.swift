//
//  ProblemInspectorView.swift
//  pgrind
//
//  Created by Zack Adlington on 21/02/2026.
//

import SwiftUI
import SwiftData

struct ProblemInspectorView: View {
    let problem: Problem

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

            switch problem {
            case let p as ImageProblem:
                imageProblemInspector(p)

            case let p as WebpageProblem:
                webpageProblemInspector(p)

            default:
                ContentUnavailableView("Unrecognized problem type", systemImage: "exclamationmark.triangle")
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var iconSystemName: String {
        switch problem {
        case _ as ImageProblem: return "photo"
        case _ as WebpageProblem: return "globe"
        default: return "questionmark"
        }
    }

    private var titleText: String {
        switch problem {
        case let p as WebpageProblem:
            return p.name
        case _ as ImageProblem:
            return "Image problem"
        default:
            return "Problem"
        }
    }

    @ViewBuilder
    private func imageProblemInspector(_ p: ImageProblem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Group {
                    if let img = NSImage(data: p.questionImage) {
                        ExpandableImageView(image: img)
                    } else {
                        ContentUnavailableView("Missing question image", systemImage: "photo")
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Divider()

            statsSection
        }
    }

    @ViewBuilder
    private func webpageProblemInspector(_ p: WebpageProblem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Links")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                LabeledContent("Question") {
                    if let url = URL(string: p.questionURL) {
                        Link(url.absoluteString, destination: url)
                    } else {
                        Text("Invalid URL")
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("Solution") {
                    if let url = URL(string: p.solutionURL) {
                        Link(url.absoluteString, destination: url)
                    } else {
                        Text("Invalid URL")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            statsSection
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stats")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let d = problem.lastAttempted {
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

    // Adaptive grid: cells at least 44pt wide, growing as space allows
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
                        .help(attempt.createdDate.formatted(date: .abbreviated, time: .shortened)   )
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
    let container = try! ModelContainer(
        for: Course.self, ProblemSet.self, WebpageProblem.self, ImageProblem.self, Attempt.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let context = container.mainContext

    let course = Course(title: "Calculus", summary: "Learn Newton's method", hyperlink: "example.com")
    let problemSet = ProblemSet(course: course, name: "Prereqs")
    let problem = WebpageProblem(
        problemSet: problemSet,
        name: "Simple numerical example 1",
        questionURL: "https://example.com",
        solutionURL: "https://example.com"
    )

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
