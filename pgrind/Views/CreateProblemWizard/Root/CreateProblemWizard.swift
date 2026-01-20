import SwiftUI
import SwiftData

enum Route: Hashable {
    case createCourse
    case createProblemSet(Course)
    case selectProblemSet(Course)
    case selectProblemKind(ProblemSet)
    case createImageProblem(ProblemSet)
    case createWebpageProblem(ProblemSet)
}

struct CreateProblemWizard: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var path: [Route] = []
    @State private var selectedCourse: Course?
    @State private var selectedProblemSet: ProblemSet?
    @State private var selectedProblemKind: ProblemKind?
    @State private var imageProblem: Problem?
    @State private var websiteProblem: Problem?
    
    var body: some View {
        NavigationStack(path: $path) {
            SelectCourse(path: $path, course: $selectedCourse, onCancel: { dismiss() })
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .createCourse:
                        CreateCourse(path: $path, selectedCourse: $selectedCourse, onCancel: { dismiss() })
                    case let .selectProblemSet(course):
                        SelectProblemSet(path: $path, course: course, selectedProblemSet: $selectedProblemSet, onCancel: { dismiss() })
                    case let .createProblemSet(course):
                        CreateProblemSet(path: $path, course: course, selectedProblemSet: $selectedProblemSet, onCancel: { dismiss() })
                    case let .selectProblemKind(problemSet):
                        SelectProblemKind(path: $path, problemSet: problemSet, selectedProblemKind: $selectedProblemKind, onCancel: { dismiss() })
                    case let .createImageProblem(problemSet):
                        CreateImageProblem(path: $path, problemSet: problemSet, onSave: { dismiss() }, onCancel: { dismiss() })
                    case let .createWebpageProblem(problemSet):
                        CreateWebpageProblem(path: $path, problemSet: problemSet, onSave: { dismiss() }, onCancel: { dismiss() })
                    }
                }
        }
        .fixedSize(horizontal: false, vertical: false)
        .frame(maxWidth: 600, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}


#Preview {
    let schema = Schema([
        Course.self,
        Problem.self
    ])

    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    let context = container.mainContext
    let sampleCourse = Course(
        title: "CS / Maths",
        summary: "Sample course for preview",
        hyperlink: "https://example.com"
    )
    context.insert(sampleCourse)

    return CreateProblemWizard()
        .modelContainer(container)
}
