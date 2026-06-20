import Foundation
import SwiftData

@Model
final class CourseFile {
    var filename: String
    var displayName: String
    var addedDate: Date = Date()

    @Relationship
    var course: Course

    init(course: Course, filename: String, displayName: String, addedDate: Date = .now) {
        self.course = course
        self.filename = filename
        self.displayName = displayName
        self.addedDate = addedDate
    }
}
