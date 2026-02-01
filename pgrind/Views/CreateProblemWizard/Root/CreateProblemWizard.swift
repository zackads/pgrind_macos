import SwiftUI
import SwiftData

struct CreateProblemWizard: View {
    enum Route: Hashable {
        case selectCourse
        case createCourse
        case createProblemSet(Course)
        case selectProblemSet(Course)
        case selectProblemKind(ProblemSet)
        case createImageProblemQuestion(ProblemSet)
        case createImageProblemSolution(ImageProblem)
        case createWebpageProblem(ProblemSet)
    }
    
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
                    case.selectCourse:
                        SelectCourse(path: $path, course: $selectedCourse, onCancel: { dismiss() })
                    case .createCourse:
                        CreateCourse(path: $path, selectedCourse: $selectedCourse, onCancel: { dismiss() })
                    case let .selectProblemSet(course):
                        SelectProblemSet(path: $path, course: course, selectedProblemSet: $selectedProblemSet, onCancel: { dismiss() })
                    case let .createProblemSet(course):
                        CreateProblemSet(path: $path, course: course, selectedProblemSet: $selectedProblemSet, onCancel: { dismiss() })
                    case let .selectProblemKind(problemSet):
                        SelectProblemKind(path: $path, problemSet: problemSet, selectedProblemKind: $selectedProblemKind, onCancel: { dismiss() })
                    case let .createImageProblemQuestion(problemSet):
                        CreateImageProblemQuestion(path: $path, problemSet: problemSet, onCancel: { dismiss() })
                    case let .createImageProblemSolution(imageProblem):
                        CreateImageProblemSolution(path: $path, imageProblem: imageProblem, onSave: { dismiss() }, onCancel: { dismiss() })
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
