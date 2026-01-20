import SwiftUI
import SwiftData

struct CreateWebpageProblem: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var path: [Route]
    var problemSet: ProblemSet
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State var problemName = ""
    @State var questionURL = ""
    @State var solutionURL = ""
    
    var body: some View {
        Form {
            TextField(
                "Name",
                text: $problemName,
                prompt: Text("E.g. 'Two sum'")
            )
            TextField(
                "Question URL",
                text: $questionURL,
                prompt: Text("E.g. 'https://leetcode.com/problems/two-sum'")
            )
            TextField(
                "Solution URL",
                text: $solutionURL,
                prompt: Text("E.g. 'https://leetcode.com/problems/two-sum/solutions'")
            )
        }
        .navigationTitle("Create a webpage problem")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let problem = WebpageProblem(
                        problemSet: problemSet,
                        name: problemName,
                        questionURL: questionURL,
                        solutionURL: solutionURL
                    )
                    modelContext.insert(problem)
                    
                    print("Inserted WebpageProblem id:", problem.persistentModelID as Any)
                    
                    onSave()
                }
                .disabled(problemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          questionURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          solutionURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

private struct PreviewHost: View {
    @State private var path: [Route] = []
    @State private var selectedProblemSet: ProblemSet? = ProblemSet(
        course: Course(
            title: "foo",
            summary: "bar",
            hyperlink: "baz"
        ),
        name: "Week 1 problem sheet")
    
    var body: some View {
        NavigationStack(path: $path) {
            if let problemSet = selectedProblemSet {
                CreateWebpageProblem(path: $path, problemSet: problemSet, onSave: {}, onCancel: {})
                    .navigationTitle("Create a new webpage problem")
            }
            
        }
    }
}

#Preview {
    PreviewHost()
}
