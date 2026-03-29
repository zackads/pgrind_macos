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
    
    @MainActor
    var imageProblems: [ImageProblem] {
        problems.compactMap { $0 as? ImageProblem }
    }
    
    @MainActor
    var webpageProblems: [WebpageProblem] {
        problems.compactMap { $0 as? WebpageProblem }
    }
    
    @MainActor
    var lastAddedTo: Date {
        return problems.map { $0.createdDate }.max() ?? Date.distantPast
    }
    
    @MainActor
    var modalProblemKind: ProblemKind? {
        let counts = problems.reduce(into: (a: 0, b: 0)) { result, element in
            switch element {
            case element as ImageProblem:
                result.a += 1
            case element as WebpageProblem:
                result.b += 1
            default:
                print("Unrecognized problem kind: \(String(describing: type(of: element)))")
            }
        }
        
        if counts.a > counts.b { return .image }
        if counts.b > counts.a { return .webpage }
        return nil
    }
    
    init(course: Course, name: String) {
        self.course = course
        self.name = name
    }
}
