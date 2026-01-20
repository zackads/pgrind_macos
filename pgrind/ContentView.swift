import SwiftUI
import SwiftData
import ScreenCaptureKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Course.createdDate) private var courses: [Course]
    
    @State private var showingAddProblem = false
    
    var body: some View {
        TabView {
            Tab("Browse", systemImage: "tray.and.arrow.up.fill") {
                BrowseView()
            }
            
            Tab("Study", systemImage: "person.crop.circle.fill") {
                StudyView()
            }
            .badge("!")
        }.toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddProblem = true
                } label: {
                    Label("Add a new problem", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
        .sheet(isPresented: $showingAddProblem) {
            CreateProblemWizard()
                .presentationSizing(.form)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ScreenshotItem.self, inMemory: true)
}
