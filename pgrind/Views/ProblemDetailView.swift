import SwiftData
import SwiftUI

struct ProblemDetailView: View {
    @Environment(\.modelContext) private var modelContext

    @Binding var path: [Home.Route]

    let problem: Problem

    @State private var isSolutionHidden: Bool = true
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var attemptNotes: String = ""

    private enum Difficulty: String, CaseIterable, Identifiable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        var id: String {
            rawValue
        }
    }

    enum Route: Hashable {
        case showQuestion(Problem)
        case recordAttempt(Problem)
    }

    var body: some View {
        VStack(spacing: 12) {
            switch problem {
            case let ip as ImageProblem:
                Image(systemName: "photo")
                Group {
                    if let problemImage = NSImage(data: ip.questionImage) {
                        ScrollView([.horizontal, .vertical]) {
                            Image(nsImage: problemImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 400)
                    } else {
                        Text("Missing problem image")
                    }
                }
            default:
                ContentUnavailableView("Unrecognized problem", systemImage: "exclamationmark.triangle")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Problem")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    path.append(.recordAttempt(problem))
                } label: {
                    Label("Attempt", systemImage: "bolt")
                }
                .labelStyle(.titleAndIcon)

                Button(role: .destructive) {
                    // If the problem is currently being shown in the navigation path, pop it first
                    if let last = path.last {
                        switch last {
                        case let .viewProblem(p) where p.persistentModelID == problem.persistentModelID:
                            _ = path.popLast()
                        case let .recordAttempt(p) where p.persistentModelID == problem.persistentModelID:
                            _ = path.popLast()
                        default:
                            break
                        }
                    }

                    // Delete the problem from the model context
                    modelContext.delete(problem)

                    // Persist changes
                    try? modelContext.save()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .help("Delete the selected problem")
                .labelStyle(.titleAndIcon)
                .keyboardShortcut(.delete, modifiers: [])
            }
        }
    }
}

#Preview("ImageProblem") {
    @Previewable @State var path: [Home.Route] = []

    let course = Course(title: "LeetCode", summary: "Grind it man", hyperlink: "https://www.leetcode.com")
    let problemSet = ProblemSet(course: course, name: "Week 0")

    ProblemDetailView(
        path: $path,
        problem: ImageProblem(
            problemSet: problemSet,
            questionImage: Data(),
            solutionImage: Data()
        )
    )
    .frame(width: 600, height: 800)
}
