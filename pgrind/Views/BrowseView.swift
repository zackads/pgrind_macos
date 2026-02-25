import SwiftUI
import SwiftData
import AppKit

private enum ViewMode {
    case thumbnail
    case heatmap
}

struct BrowseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    
    @Query(sort: \Course.createdDate, order: .forward) private var courses: [Course]
    @Query(sort: \ProblemSet.createdDate, order: .forward) private var problemSets: [ProblemSet]
    @Query(sort: \Problem.createdDate, order: .forward) private var problems: [Problem]
    
    @State var path: [ProblemDetailView.Route] = []
    @State private var selectedCourse: Course?
    @State private var selectedProblem: Problem?
    
    @State private var showInspector = false
    @State private var viewMode: ViewMode = ViewMode.heatmap
    
    var body: some View {
        NavigationSplitView {
            sidebar(courses: courses)
        } detail: {
            NavigationStack(path: $path) {
                Group {
                    if let selectedCourse {
                        List(selectedCourse.problemSets) { ps in
                            VStack(alignment: .leading) {
                                Text(ps.name)
                                    .font(.title3)
                                Group {
                                    switch viewMode {
                                    case .thumbnail:
                                        ProblemsGalleryView(problems: ps.problems) { problem in
                                            selectedProblem = problem
                                            path.append(.showQuestion(problem))
                                        }
                                    case .heatmap:
                                        ProblemsHeatmapView(problems: ps.problems) { problem in
                                            selectedProblem = problem
                                            path.append(.showQuestion(problem))
                                        }
                                    }
                                }
                            }
                            .tag(ps)
                        }
                        .navigationTitle(selectedCourse.title)
                    } else {
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
        .onChange(of: selectedCourse) { _, _ in
            selectedProblem = nil
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    openWindow(id: "create-problem")
                } label: {
                    Label("Add a new problem", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    showInspector.toggle()
                } label: {
                    Label(showInspector ? "Hide Inspector" : "Show Inspector",
                          systemImage: "sidebar.right")
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
            }
            ToolbarItem(placement: .status) {
                Picker("View", selection: $viewMode) {
                    Label("Thumbnails", systemImage: "photo.stack").tag(ViewMode.thumbnail)
                    Label("Heatmap", systemImage: "flame").tag(ViewMode.heatmap)
                }
                .pickerStyle(.segmented)
                .help("Toggle between thumbnail and heatmap views")
            }
        }
    }
    
    private func sidebar(courses: [Course]) -> some View {
        VStack {
            Text("📚 Courses")
            List(courses, selection: $selectedCourse) { course in
                Text(course.title).tag(course)
            }
            .navigationTitle("Courses")
            .onDeleteCommand {
                if let toDelete = selectedCourse {
                    modelContext.delete(toDelete)
                    
                    selectedCourse = nil
                    selectedProblem = nil
                    
                    try? modelContext.save()
                }
            }
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
                    case let p as WebpageProblem:
                        HStack {
                            Image(systemName: "globe")
                            Text(p.name)
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
        WebpageProblem.self,
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

    // Sample problems: webpage and image kinds
    let webpageProblem = WebpageProblem(
        problemSet: ps1,
        name: "Limits Basics",
        questionURL: "https://example.com/limits",
        solutionURL: "https://example.com/limits-solution"
    )
    let imageProblem = ImageProblem(
        problemSet: ps1,
        questionImage: Data(),
        solutionImage: Data(),
    )
    let leetcodeProblem = WebpageProblem(
        problemSet: ps2,
        name: "Two Sum",
        questionURL: "https://leetcode.com/problems/two-sum/",
        solutionURL: "https://example.com/two-sum-solution"
    )
    context.insert(webpageProblem)
    context.insert(imageProblem)
    context.insert(leetcodeProblem)
    try? context.save()
    
    let a1 = Attempt(problem: webpageProblem, difficulty: .medium)
    let a2 = Attempt(problem: webpageProblem, difficulty: .easy)
    let a3 = Attempt(problem: imageProblem, difficulty: .hard)
    let a4 = Attempt(problem: imageProblem, difficulty: .hard)
    context.insert(a1)
    context.insert(a2)
    context.insert(a3)
    context.insert(a4)
    try? context.save()

    return BrowseView()
        .modelContainer(container)
}
