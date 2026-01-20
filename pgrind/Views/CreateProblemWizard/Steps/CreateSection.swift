import SwiftUI
import SwiftData

struct CreateProblemSet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Binding var path: [Route]
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
                    let trimmed_name = problemSetName.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let newProblemSet = ProblemSet(
                        course: course,
                        name: trimmed_name
                    )
                    
                    modelContext.insert(newProblemSet)
                    
                    selectedProblemSet = newProblemSet
                    
                    path.append(.selectProblemKind(newProblemSet))
                }
                .disabled(problemSetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
