import Foundation
import SwiftData

@Model
final class ProblemSet {
    var name: String // e.g. "Week 1", "2023 past paper", "Chapter 12"
    
    @Relationship
    var course: Course
    
    var createdDate: Date = Date()
    
    @Relationship(deleteRule: .cascade, inverse: \Problem.problemSet)
    var problems: [Problem] = []
    
    var imageProblems: [ImageProblem] {
        problems.compactMap { $0 as? ImageProblem }
    }
    
    var webpageProblems: [WebpageProblem] {
        problems.compactMap { $0 as? WebpageProblem }
    }
    
    init(course: Course, name: String) {
        self.course = course
        self.name = name
    }
}
