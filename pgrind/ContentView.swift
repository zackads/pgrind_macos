import SwiftUI
import SwiftData
import ScreenCaptureKit

struct ContentView: View {
    var body: some View {
        Home()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ScreenshotItem.self, inMemory: true)
}
