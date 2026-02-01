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
            TextField(text: $courseSummary, prompt: Text("E.g. 'Master the calculus of derivatives, integrals, coordinate systems, and infinite series.'"), axis: .vertical) {
                Text("Description")
            }
            .lineLimit(3...5)
            TextField(text: $courseHyperlink, prompt: Text("E.g. 'https://ocw.mit.edu/courses/18-01-calculus-i-single-variable-calculus-fall-2020/'")) {
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
