import SwiftUI

struct StudyProblemView: View {
    @Binding var path: [ProblemDetailView.Route]
    let problem: Problem
    
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var attemptNotes: String = ""

    enum Difficulty: String, CaseIterable, Identifiable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                switch problem {
                case let ip as ImageProblem:
                    if let problemImage = NSImage(data: ip.questionImage) {
                        Image(nsImage: problemImage)
                    } else {
                        ContentUnavailableView("Missing question image", systemImage: "photo")
                    }
                case let wp as WebpageProblem:
                    VStack {
                        Text("Name goes here").font(.title2)

                        if let questionURL = URL(string: wp.questionURL) {
                            Link(destination: questionURL) {
                                Label("Open question", systemImage: "arrow.up.right.square")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                default:
                    ContentUnavailableView("Unrecognized problem", systemImage: "exclamationmark.triangle")
                }
                HStack {
                    Spacer()
                    Button(action: { path.append(.recordAttempt(problem)) }) {
                        Label("Show solution", systemImage: "eye")
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Problem")
            .toolbar {
                Button {
                    path.append(.recordAttempt(problem))
                } label: {
                    Label("Record attempt", systemImage: "square.and.pencil")
                }
                .help("Record a new attempt for this problem")
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview("ImageProblem") {
    let course = Course(title: "LeetCode", summary: "Grind it man", hyperlink: "https://www.leetcode.com")
    let problemSet = ProblemSet(course: course, name: "Week 0")
    
    StudyProblemView(
        path: .constant([]),
        problem: ImageProblem(
            problemSet: problemSet,
            questionImage: Data(),
            solutionImage: Data()
        )
    )
}

#Preview("WebpageProblem") {
    let course = Course(title: "LeetCode", summary: "Grind it man", hyperlink: "https://www.leetcode.com")
    let problemSet = ProblemSet(course: course, name: "Week 0")
    
    StudyProblemView(
        path: .constant([]),
        problem: WebpageProblem(
            problemSet: problemSet,
            name: "Sample Algebra Problem",
            questionURL: "https://example.com/question",
            solutionURL: "https://example.com/solution"
        )
    )
}
