import SwiftUI
import SwiftData
import AppKit

private enum ViewMode {
    case thumbnail
    case heatmap
}

struct Home: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    
    @Query(sort: \Course.createdDate, order: .forward) private var courses: [Course]
    @Query(sort: \ProblemSet.createdDate, order: .forward) private var problemSets: [ProblemSet]
    @Query(sort: \Problem.createdDate, order: .forward) private var problems: [Problem]
    @Query(sort: \Deck.createdDate, order: .forward) private var decks: [Deck]
    
    @State var path: [ProblemDetailView.Route] = []
    
    enum SidebarItem: Hashable {
        case course(Course)
    }
    @State private var selectedSidebarItem: SidebarItem?
    var selectedCourse: Course? {
        if case .course(let course) = selectedSidebarItem { return course }
        return nil
    }
    
    @State private var selectedProblem: Problem?
    
    @State private var showInspector = false
    @State private var viewMode: ViewMode = ViewMode.heatmap
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedSidebarItem: $selectedSidebarItem, courses: courses)
        } detail: {
            NavigationStack(path: $path) {
                Group {
                    switch selectedSidebarItem {
                    case .course(let course):
                        CourseView(path: $path, course: course)
                    case nil:
                        ContentUnavailableView("Select a course", systemImage: "books.vertical")
                    }
                }
                .navigationDestination(for: ProblemDetailView.Route.self) { route in
                    switch route {
                    case let .showQuestion(problem):
                        ProblemDetailView(path: $path, problem: problem)
                    case let .recordAttempt(problem):
                        RecordAttemptView(path: $path, problem: problem)
                    }
                }
            }
        }
        .inspector(isPresented: $showInspector) {
            Group {
                if let selectedProblem {
                    ProblemInspectorView(problem: selectedProblem)
                } else {
                    ContentUnavailableView("Select a problem", systemImage: "document.on.document")
                }
            }
        }
        .onChange(of: selectedSidebarItem) { _, _ in
            selectedProblem = nil
        }
    }
    
    private func inspector(problemSet: ProblemSet?) -> some View {
        Group {
            if let problemSet {
                List(problemSet.problems, selection: $selectedProblem) { problem in
                    switch problem {
                    case let p as ImageProblem:
                        HStack {
                            Image(systemName: "photo")
                            if let problemImage = NSImage(data: p.questionImage) {
                                ExpandableImageView(image: problemImage)
                            } else {
                                Text("Missing problem image")
                            }
                        }
                        .tag(problem)
                    default:
                        EmptyView()
                    }
                }
                .navigationTitle(problemSet.name)
            } else {
                ContentUnavailableView("Select a problem set", systemImage: "document.on.document")
            }
        }
    }
}

#Preview {
    let schema = Schema([
        Course.self,
        ProblemSet.self,
        Problem.self,
        ImageProblem.self,
        Attempt.self,
    ])

    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    let context = container.mainContext

    // Sample Courses
    let analysis = Course(
        title: "Real Analysis",
        summary: "Introductory real analysis course",
        hyperlink: "https://example.com/analysis"
    )
    let algorithms = Course(
        title: "Algorithms",
        summary: "Design and analysis of algorithms",
        hyperlink: "https://example.com/algorithms"
    )
    context.insert(analysis)
    context.insert(algorithms)
    try? context.save()
    
    // Sample ProblemSets
    let ps1 = ProblemSet(course: analysis, name: "Week 1 problem sheet")
    let ps2 = ProblemSet(course: algorithms, name: "Week 2 problem sheet")
    context.insert(ps1)
    context.insert(ps2)
    try? context.save()
    
    let imageProblem = ImageProblem(
        problemSet: ps1,
        questionImage: Data(),
        solutionImage: Data(),
    )
    context.insert(imageProblem)
    try? context.save()
    
    let a3 = Attempt(problem: imageProblem, difficulty: .hard)
    let a4 = Attempt(problem: imageProblem, difficulty: .hard)
    context.insert(a3)
    context.insert(a4)
    try? context.save()

    return Home()
        .modelContainer(container)
}
