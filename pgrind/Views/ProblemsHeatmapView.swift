import SwiftUI
import SwiftData

struct ProblemsHeatmapView: View {
    let problems: [Problem]
    let onSelect: (Problem) -> Void

    @Query private var attempts: [Attempt]

    init(problems: [Problem], onSelect: @escaping (Problem) -> Void) {
        self.problems = problems
        self.onSelect = onSelect

        let ids = problems.map { $0.persistentModelID }
        _attempts = Query(filter: #Predicate<Attempt> { a in
            ids.contains(a.problem.persistentModelID)
        })
    }

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 12, maximum: 12), spacing: 2, alignment: .leading)
    ]

    /// Latest attempt difficulty per problem (by timestamp).
    private var latestDifficultyByProblemID: [PersistentIdentifier: Difficulty] {
        var best: [PersistentIdentifier: (timestamp: Date, difficulty: Difficulty)] = [:]

        for a in attempts {
            let id = a.problem.persistentModelID
            if let existing = best[id] {
                if a.createdDate > existing.timestamp {
                    best[id] = (a.createdDate, a.difficulty)
                }
            } else {
                best[id] = (a.createdDate, a.difficulty)
            }
        }

        return best.mapValues { $0.difficulty }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(problems) { problem in
                let difficulty = latestDifficultyByProblemID[problem.persistentModelID] ?? .notAttempted
                ProblemHeatmapCell(problem: problem, difficulty: difficulty, onSelect: onSelect)
            }
        }
    }
}

private struct ProblemHeatmapCell: View {
    @Bindable var problem: Problem
    let difficulty: Difficulty
    let onSelect: (Problem) -> Void

    var body: some View {
        Button {
            onSelect(problem)
        } label: {
            Rectangle()
                .fill(color(for: difficulty))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 1)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .accessibilityLabel(accessibilityLabel(for: problem, difficulty: difficulty))
                .accessibilityHint("Open problem details")
        }
        .buttonStyle(.plain)
    }

    private func color(for difficulty: Difficulty) -> Color {
        switch difficulty {
        case .notAttempted: return .gray.opacity(0.7)
        case .easy:         return .green.opacity(0.7)
        case .medium:       return .orange.opacity(0.7)
        case .hard:         return .red.opacity(0.7)
        }
    }

    private func accessibilityLabel(for problem: Problem, difficulty: Difficulty) -> String {
        switch problem {
        case let wp as WebpageProblem:
            return "\(wp.name), \(difficulty.rawValue)"
        case _ as ImageProblem:
            return "Image problem added on \(problem.createdDate.formatted()), \(difficulty.rawValue)"
        default:
            return "Problem, \(difficulty.rawValue)"
        }
    }
}
