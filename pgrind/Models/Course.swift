import Foundation
import SwiftData

@Model
final class Course {
    var title: String   // e.g. "18.100A | Real Analysis | Fall 2020"
    var summary: String
    var hyperlink: String     // e.g. https://ocw.mit.edu/courses/18-100a-real-analysis-fall-2020/
    var createdDate: Date = Date()
    
    @Relationship(deleteRule: .cascade, inverse: \ProblemSet.course)
    var problemSets: [ProblemSet] = []
    
    var problems: [Problem] {
        return problemSets.flatMap(\.problems)
    }
    
    init(title: String, summary: String, hyperlink: String) {
        self.title = title
        self.summary = summary
        self.hyperlink = hyperlink
    }
}
