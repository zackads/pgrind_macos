import SwiftData
import SwiftUI

struct RecordAttemptView: View {
    enum Tab: Hashable {
        case question, solution
    }

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    @Binding var path: [Home.Route]
    var problem: ImageProblem
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var selectedTab: Tab = .question
    @State private var notes: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()

                TabView(selection: $selectedTab) {
                    ScrollView {
                        VStack {
                            if let questionImage = NSImage(data: problem.questionImage) {
                                ExpandableImageView(image: questionImage, maxSize: nil)
                            } else {
                                ContentUnavailableView("Missing question image", systemImage: "photo")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .tabItem { Label("Question", systemImage: "doc.text") }
                    .tag(Tab.question)

                    ScrollView {
                        VStack(spacing: 16) {
                            if let data = problem.solutionImage, let solutionImage = NSImage(data: data) {
                                ExpandableImageView(image: solutionImage, maxSize: nil)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ContentUnavailableView("Missing solution image", systemImage: "photo")
                                    .frame(maxWidth: .infinity)
                            }

                            HStack {
                                Spacer()
                                Picker("", selection: $selectedDifficulty) {
                                    let difficulties = Difficulty.allCases.filter { $0 != .notAttempted }
                                    ForEach(difficulties, id: \.self) { difficulty in
                                        Text(String(describing: difficulty)).tag(difficulty)
                                    }
                                }
                                .pickerStyle(.segmented)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes").font(.headline)
                                TextEditor(text: $notes)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 140)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.secondary.opacity(0.08))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Color.secondary.opacity(0.3))
                                    )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                    }
                    .tabItem { Label("Solution", systemImage: "checkmark.circle") }
                    .tag(Tab.solution)
                }
            }
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
                    problem.inInbox = false

                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
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
