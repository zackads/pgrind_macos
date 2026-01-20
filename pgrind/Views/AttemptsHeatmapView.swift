import SwiftUI
import SwiftData

struct AttemptsHeatmapView: View {
    let attempts: [Attempt]
    let onSelect: (Attempt) -> Void

    // Adaptive grid: cells at least 44pt wide, growing as space allows
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 44, maximum: 44), spacing: 8, alignment: .center)
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityHint("Open attempt details")
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(width: 200, height: 200, alignment: .center)
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

#Preview("Heatmap of sample attempts") {
    let course = Course(title: "Sample Course", summary: "A course to preview the heatmap", hyperlink: "https://example.com")
    let ps = ProblemSet(course: course, name: "Week 0")
    
    let problem = ImageProblem(problemSet: ps, questionImage: Data(), solutionImage: nil)
    
    let a1 = Attempt(problem: problem, difficulty: .notAttempted)
    let a2 = Attempt(problem: problem, difficulty: .easy)
    let a3 = Attempt(problem: problem, difficulty: .medium)
    let a4 = Attempt(problem: problem, difficulty: .hard)
    
    AttemptsHeatmapView(attempts: [a1, a2, a3, a4], onSelect: { _ in })
}
