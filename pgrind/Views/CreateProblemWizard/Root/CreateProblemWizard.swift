import SwiftData
import SwiftUI

struct CreateProblemWizard: View {
    enum Route: Hashable {
        case selectCourse
        case createCourse
        case createProblemSet(Course)
        case selectProblemSet(Course)
        case createImageProblemQuestion(ProblemSet)
        case createImageProblemSolution(ImageProblem)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let courseID: PersistentIdentifier?
    var course: Course? {
        guard let courseID else { return nil }
        return modelContext.model(for: courseID) as? Course
    }

    @State private var path: [Route] = []
    @State private var selectedCourse: Course?
    @State private var selectedProblemSet: ProblemSet?
    @State private var selectedProblemKind: ProblemKind?
    @State private var imageProblem: ImageProblem?

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let course {
                    SelectProblemSet(path: $path, course: course, selectedProblemSet: $selectedProblemSet, onCancel: { dismiss() })
                } else {
                    SelectCourse(path: $path, course: $selectedCourse, onCancel: { dismiss() })
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .selectCourse:
                    SelectCourse(path: $path, course: $selectedCourse, onCancel: { dismiss() })
                case .createCourse:
                    CreateCourse(path: $path, selectedCourse: $selectedCourse, onCancel: { dismiss() })
                case let .selectProblemSet(course):
                    SelectProblemSet(path: $path, course: course, selectedProblemSet: $selectedProblemSet, onCancel: { dismiss() })
                case let .createProblemSet(course):
                    CreateProblemSet(path: $path, course: course, selectedProblemSet: $selectedProblemSet, onCancel: { dismiss() })
                case let .createImageProblemQuestion(problemSet):
                    CreateImageProblemQuestion(path: $path, problemSet: problemSet, onCancel: { dismiss() })
                case let .createImageProblemSolution(imageProblem):
                    CreateImageProblemSolution(path: $path, imageProblem: imageProblem, onSave: { dismiss() }, onCancel: { dismiss() })
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
        ImageProblem.self
    ])

    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container: ModelContainer
    do {
        container = try ModelContainer(for: schema, configurations: [config])
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }

    let context = container.mainContext
    let sampleCourse = Course(
        title: "CS / Maths",
        summary: "Sample course for preview",
        hyperlink: "https://example.com"
    )
    context.insert(sampleCourse)

    return CreateProblemWizard(courseID: nil)
        .modelContainer(container)
}
