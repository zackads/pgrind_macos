import SwiftUI
import SwiftData

struct RecordAttemptView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Binding var path: [ProblemDetailView.Route]
    var problem: Problem
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var notes: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                switch problem {
                case let ip as ImageProblem:
                    RecordImageProblemAttemptView(problem: ip)
                case let wp as WebpageProblem:
                    if let solutionURL = URL(string: wp.solutionURL) {
                        Link(destination: solutionURL) {
                            Label("Open solution", systemImage: "arrow.up.right.square")
                        }
                        .buttonStyle(.bordered)
                    } else {
                        ContentUnavailableView("No solution webpage available", systemImage: "safari")
                    }
                default:
                    ContentUnavailableView("Unrecognized problem", systemImage: "exclamationmark.triangle")
                }
                Spacer()
            }
            HStack {
                Spacer()
                Picker("", selection: $selectedDifficulty) {
                    ForEach(Difficulty.allCases.filter { $0 != .notAttempted}, id: \.self) { d in
                        Text(String(describing: d)).tag(d)
                    }
                }
                .pickerStyle(.segmented)
                Spacer()
            }
            
            Text("Notes").font(.headline)
            TextEditor(text: $notes)
                .frame(minHeight: 120)
                .padding(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.secondary.opacity(0.3))
                )

            Spacer()
        }
        .padding()
        .navigationTitle("Record attempt")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    modelContext.insert(
                        Attempt(
                            problem: problem,
                            difficulty: selectedDifficulty,
                            notes: notes)
                    )
                    
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}

struct RecordImageProblemAttemptView: View {
    enum Tab: Hashable {
        case question, solution
    }
    
    var problem: ImageProblem
    @State private var selectedTab: Tab = .solution
    
    var body: some View {
        VStack {
            switch selectedTab {
            case .question:
                Group {
                    if let questionImage = NSImage(data: problem.questionImage) {
                        ExpandableImageView(image: questionImage)
                    } else {
                        ContentUnavailableView("Missing question image", systemImage: "photo")
                    }
                }
                .tabItem { Label("Question", systemImage: "photo") }
                .tag(Tab.question)
            case .solution:
                Group {
                    if let data = problem.solutionImage, let solutionImage = NSImage(data: data) {
                        ExpandableImageView(image: solutionImage)
                    } else {
                        ContentUnavailableView("Missing solution image", systemImage: "photo")
                    }
                }
                .tabItem { Label("Solution", systemImage: "photo") }
                .tag(Tab.solution)
            }
        }
    }
}



#Preview("WebpageProblem") {
    let course = Course(
        title: "Test course",
        summary: "A test course for testing purposes",
        hyperlink: "http://example.com/course"
    )
    let problemSet = ProblemSet(course: course, name: "Week 3")
    let problem = WebpageProblem(
        problemSet: problemSet,
        name: "Test problem",
        questionURL: "https://example.com/question",
        solutionURL: "https://example.com/solution"
    )
    RecordAttemptView(path: .constant([]), problem: problem)
}

#Preview("ImageProblem") {
    let course = Course(
        title: "Test course",
        summary: "A test course for testing purposes",
        hyperlink: "http://example.com/course"
    )
    let problemSet = ProblemSet(course: course, name: "Week 3")
    let problem = ImageProblem(
        problemSet: problemSet,
        questionImage: Data(),
        solutionImage: Data(),
    )
    RecordAttemptView(path: .constant([]), problem: problem)
}
