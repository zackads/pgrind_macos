import Foundation
import SwiftData
import Combine

@Model
class Problem {
    var createdDate: Date
    
    @Relationship
    var problemSet: ProblemSet
    
    @Relationship(deleteRule: .cascade, inverse: \Attempt.problem)
    var attempts: [Attempt] = []
    
    init(problemSet: ProblemSet, createdDate: Date = Date()) {
        self.problemSet = problemSet
        self.createdDate = createdDate
    }
    
    var currentDifficulty: Difficulty {
        guard let latest = attempts.max(by: {$0.createdDate < $1.createdDate }) else {
            return .notAttempted
        }
        return latest.difficulty
    }
    
    var lastAttempted: Date? {
        guard let latest = attempts.max(by: {$0.createdDate < $1.createdDate }) else { return nil }
        return latest.createdDate
    }
}
