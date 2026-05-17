import SwiftData
import SwiftUI

struct CreateProblemSet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @Binding var path: [CreateProblemWizard.Route]
    let course: Course
    @Binding var selectedProblemSet: ProblemSet?
    let onCancel: () -> Void

    @State var problemSetName: String = ""

    var body: some View {
        Form {
            TextField(text: $problemSetName, prompt: Text("E.g. 'Week 4 problem sheet', 'Chapter 12' or '2022 Summer exam paper")) {
                Text("Name")
            }
        }
        .navigationTitle("Create a new problem set in \(course.title)")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Continue") {
                    let trimmedName = problemSetName.trimmingCharacters(in: .whitespacesAndNewlines)

                    let newProblemSet = ProblemSet(
                        course: course,
                        name: trimmedName
                    )

                    course.problemSets.append(newProblemSet)

                    selectedProblemSet = newProblemSet

                    path.append(.createImageProblemQuestion(newProblemSet))
                }
                .disabled(problemSetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
