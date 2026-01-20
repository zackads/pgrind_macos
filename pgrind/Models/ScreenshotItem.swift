import Foundation
import SwiftData

@Model
final class ScreenshotItem {
    var timestamp: Date
    
    @Attribute(.externalStorage)
    var pngData: Data
    
    init(timestamp: Date = .now, pngData: Data) {
        self.timestamp = timestamp
        self.pngData = pngData
    }
}
