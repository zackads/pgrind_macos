import SwiftData
import SwiftUI

@main
struct PgrindApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: MigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            print("ModelContainer init failed:", String(reflecting: error))
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var scheduler: StudyPlanScheduler?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    if scheduler == nil {
                        let newScheduler = StudyPlanScheduler(modelContext: sharedModelContainer.mainContext)
                        newScheduler.start()
                        scheduler = newScheduler
                    }
                }
        }
        .modelContainer(sharedModelContainer)

        WindowGroup(id: "create-problem", for: PersistentIdentifier.self) { $courseID in
            if let courseID {
                CreateProblemWizard(courseID: courseID)
            } else {
                CreateProblemWizard(courseID: nil)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
