import SwiftUI
import SwiftData
import AppKit

struct BrowseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    
    @Query(sort: \Course.createdDate, order: .forward) private var courses: [Course]
    @Query(sort: \ProblemSet.createdDate, order: .forward) private var problemSets: [ProblemSet]
    @Query(sort: \Problem.createdDate, order: .forward) private var problems: [Problem]
    
    @State var path: [ProblemDetailView.Route] = []
    @State private var selectedCourseID: PersistentIdentifier?
    @State private var selectedProblemSetID: PersistentIdentifier?
    @State private var selectedProblemID: PersistentIdentifier?
    
    private var selectedCourse: Course? {
        return courses.first { $0.persistentModelID == selectedCourseID }
    }
    
    private var selectedProblemSet: ProblemSet? {
        problemSetsForSelectedCourse.first { $0.persistentModelID == selectedProblemSetID }
    }
    
    private var problemSetsForSelectedCourse: [ProblemSet] {
        return problemSets
            .filter { $0.course.persistentModelID == selectedCourse?.persistentModelID }
    }

    private var problemsForSelectedProblemSet: [Problem] {
        return problems
            .filter { $0.problemSet.persistentModelID == selectedProblemSet?.persistentModelID }
    }
    
    var body: some View {
        NavigationSplitView {
            coursesColumn
        } content: {
            problemSetsColumn
        } detail: {
            detailColumn
        }
        .onChange(of: selectedCourseID) { _, _ in
            selectedProblemSetID = nil
            selectedProblemID = nil
        }
        .onChange(of: selectedProblemSetID) { _, _ in
            selectedProblemID = nil
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
        }
    }
    
    private var coursesColumn: some View {
        List(courses, selection: $selectedCourseID) { course in
            Text(course.title).tag(course.persistentModelID)
        }
        .navigationTitle("Courses")
        .onDeleteCommand {
            guard let id = selectedCourseID, let course = courses.first(where: { $0.persistentModelID == id }) else { return }
            modelContext.delete(course)
            selectedCourseID = nil
            selectedProblemSetID = nil
            selectedProblemID = nil
            try? modelContext.save()
        }
    }
    
    private var problemSetsColumn: some View {
        Group {
            if let course = selectedCourse {
                List(problemSetsForSelectedCourse, selection: $selectedProblemSetID) { ps in
                    VStack(alignment: .leading) {
                        Text(ps.name)
                        ProblemsHeatmapView(
                            problems: ps.problems,
                            onSelect: { _ in }
                        )
                        Divider()
                    }
                }
                .navigationTitle(course.title)
                .onDeleteCommand {
                    guard let id = selectedProblemSetID, let ps = problemSetsForSelectedCourse.first(where: { $0.persistentModelID == id }) else { return }
                    modelContext.delete(ps)
                    selectedProblemSetID = nil
                    selectedProblemID = nil
                    try? modelContext.save()
                }
            } else {
                ContentUnavailableView("Select a course", systemImage: "books.vertical")
            }
        }
    }
    
    private var detailColumn: some View {
        NavigationStack(path: $path) {
            if let ps = selectedProblemSet {
                List(problemsForSelectedProblemSet, selection: $selectedProblemID) { problem in
                    HStack(spacing: 12) {
                        switch problem {
                        case let ip as ImageProblem:
                            Image(systemName: "photo")
                            Group {
                                if let problemImage = NSImage(data: ip.questionImage) {
                                    ExpandableImageView(image: problemImage)
                                } else {
                                    Text("Missing problem image")
                                }
                            }
                        case let wp as WebpageProblem:
                            Image(systemName: "globe")
                            Text(wp.name)
                            if let questionURL = URL(string: wp.questionURL) {
                                Link(destination: questionURL) {
                                    Label("Open question", systemImage: "arrow.up.right.square")
                                }
                                .buttonStyle(.bordered)
                            }
                        default:
                            ContentUnavailableView("Unrecognized problem", systemImage: "exclamationmark.triangle")
                        }
                        
                        Spacer()
                        
                        Button(action: { path.append(.showQuestion(problem)) }) {
                            Label("Attempt", systemImage: "square.and.pencil")
                        }
                        .buttonStyle(.borderedProminent)
                        .tag(problem.persistentModelID)
                    }
                }
                .navigationTitle(ps.name)
                .onDeleteCommand {
                    guard
                        let id = selectedProblemID,
                        let problem = problemsForSelectedProblemSet.first(where: { $0.persistentModelID == id }) else { return }
                    modelContext.delete(problem)
                    selectedProblemID = nil
                    try? modelContext.save()
                }
            } else if selectedCourse != nil {
                ContentUnavailableView("Select a problem set", systemImage: "document.on.document")
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
        
    private func deleteProblemSets(at offsets: IndexSet) {
        let toDelete = offsets.map { problemSetsForSelectedCourse[$0] }
        toDelete.forEach(modelContext.delete)
        if let selected = selectedProblemSetID, toDelete.contains(where: { $0.persistentModelID == selected }) {
            selectedProblemSetID = nil
            selectedProblemID = nil
        }
        try? modelContext.save()
    }
    
//    private func deleteProblems(at offsets: IndexSet) {
//        guard let selectedCourse else { return }
//        
//        let toDelete = offsets.map { selectedCourse.problems[$0] }
//        for problem in toDelete {
//            modelContext.delete(problem)
//        }
//        
//        if let id = selectedProblemID, toDelete.contains(where: { $0.persistentModelID == id }) {
//            selectedProblemID = nil
//        }
//    }
//    
//    private func delete(_ problem: Problem) {
//        modelContext.delete(problem)
//        if selectedProblemID == problem.persistentModelID {
//            selectedProblemID = nil
//        }
//        try? modelContext.save()
//    }
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
