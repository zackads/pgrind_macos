import SwiftUI
import SwiftData

struct CreateCourse: View {
    @Binding var path: [CreateProblemWizard.Route]
    @Binding var selectedCourse: Course?
    
    @State var courseTitle: String = ""
    @State var courseSummary: String = ""
    @State var courseHyperlink: String = ""
    let onCancel: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Form {
            TextField(text: $courseTitle, prompt: Text("E.g. 'MIT 18.01 | Single Variable Calculus | Fall 2020'")) {
                Text("Name")
            }
            TextField(text: $courseSummary, prompt: Text("E.g. 'xxx'")) {
                Text("Description")
            }
            TextField(text: $courseHyperlink, prompt: Text("E.g. 'xxx'")) {
                Text("Website URL")
            }
        }
        .navigationTitle("Create a new course")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Continue") {
                    let newCourse = Course(
                        title: courseTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                        summary: courseSummary.trimmingCharacters(in: .whitespacesAndNewlines),
                        hyperlink: courseHyperlink.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    
                    modelContext.insert(newCourse)
                    
                    selectedCourse = newCourse
                    
                    path.removeAll()
                }
                .disabled(courseTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          courseSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          courseHyperlink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

private struct PreviewHost: View {
    @State private var path: [CreateProblemWizard.Route] = []
    @State private var createdCourse: Course?
    
    var body: some View {
        NavigationStack(path: $path) {
            CreateCourse(path: $path, selectedCourse: $createdCourse, onCancel: {})
                .navigationTitle("Create a new course")
        }
    }
}

#Preview {
    PreviewHost()
}
