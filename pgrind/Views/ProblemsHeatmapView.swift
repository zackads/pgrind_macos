import SwiftUI
import SwiftData

struct ProblemsHeatmapView: View {
    let problems: [Problem]
    let onSelect: (Problem) -> Void

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 12, maximum: 12), spacing: 2, alignment: .leading)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(problems) { problem in
                let difficulty = problem.currentDifficulty
                
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
