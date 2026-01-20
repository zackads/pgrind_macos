import SwiftUI

struct ProblemDetailView: View {
    @Binding var path: [ProblemDetailView.Route]
    
    let problem: Problem
    
    @State private var isSolutionHidden: Bool = true
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var attemptNotes: String = ""

    private enum Difficulty: String, CaseIterable, Identifiable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        var id: String { rawValue }
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
                        ExpandableImageView(image: problemImage)
                    } else {
                        Text("Missing problem image")
                    }
                }
            case let wp as WebpageProblem:
                Image(systemName: "globe")
                Text(wp.name)
                if let questionURL = URL(string: wp.questionURL) {
                    Link(destination: questionURL) {
                        Label("Open question", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.bordered)
                }
            default:
                ContentUnavailableView("Unrecognized problem", systemImage: "exclamationmark.triangle")
            }
            
            Spacer()
            
            Button(action: { path.append(.recordAttempt(problem)) }) {
                Label("Show solution", systemImage: "eye")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Problem")
    }
}

#Preview("ImageProblem") {
    @Previewable @State var path: [ProblemDetailView.Route] = []
    
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

#Preview("WebpageProblem") {
    @Previewable @State var path: [ProblemDetailView.Route] = []
    
    let course = Course(title: "LeetCode", summary: "Grind it man", hyperlink: "https://www.leetcode.com")
    let problemSet = ProblemSet(course: course, name: "Week 0")
    
    ProblemDetailView(
        path: $path,
        problem: WebpageProblem(
            problemSet: problemSet,
            name: "Sample Algebra Problem",
            questionURL: "https://example.com/question",
            solutionURL: "https://example.com/solution"
        )
    )
    .frame(width: 600, height: 800)
}
