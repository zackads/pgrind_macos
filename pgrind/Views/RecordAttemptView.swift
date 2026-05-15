import SwiftData
import SwiftUI

struct RecordAttemptView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    @Binding var path: [Home.Route]
    var problem: ImageProblem
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var notes: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()

                RecordImageProblemAttemptView(problem: problem)

                Spacer()
            }
            HStack {
                Spacer()
                Picker("", selection: $selectedDifficulty) {
                    ForEach(Difficulty.allCases.filter { $0 != .notAttempted }, id: \.self) { d in
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
                    problem.attempts.append(
                        Attempt(
                            problem: problem,
                            difficulty: selectedDifficulty,
                            notes: notes
                        )
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
        TabView(selection: $selectedTab) {
            Group {
                if let questionImage = NSImage(data: problem.questionImage) {
                    ExpandableImageView(image: questionImage, maxSize: nil)
                } else {
                    ContentUnavailableView("Missing question image", systemImage: "photo")
                }
            }
            .tabItem { Label("Question", systemImage: "doc.text") }
            .tag(Tab.question)

            Group {
                if let data = problem.solutionImage, let solutionImage = NSImage(data: data) {
                    ExpandableImageView(image: solutionImage, maxSize: nil)
                } else {
                    ContentUnavailableView("Missing solution image", systemImage: "photo")
                }
            }
            .tabItem { Label("Solution", systemImage: "checkmark.circle") }
            .tag(Tab.solution)
        }
    }
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
        solutionImage: Data()
    )
    RecordAttemptView(path: .constant([]), problem: problem)
}
