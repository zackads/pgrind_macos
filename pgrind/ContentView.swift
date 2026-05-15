import ScreenCaptureKit
import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        Home()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ScreenshotItem.self, inMemory: true)
}
