import SwiftUI
import SwiftData
import ScreenCaptureKit

struct ContentView: View {
    var body: some View {
        BrowseView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ScreenshotItem.self, inMemory: true)
}
