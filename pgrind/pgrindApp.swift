import SwiftUI
import SwiftData

@main
struct pgrindApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Attempt.self,
            Course.self,
            ProblemSet.self,
            Problem.self,
            ImageProblem.self,
            WebpageProblem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        
        WindowGroup(id: "create-problem") {
            CreateProblemWizard()
        }
        .modelContainer(sharedModelContainer)
    }
}
