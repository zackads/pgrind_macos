import Foundation
import SwiftData

@Model
final class ImageProblem {
    @Attribute(.externalStorage)
    var questionImage: Data
    @Attribute(.externalStorage)
    var solutionImage: Data?

    init(problemSet: ProblemSet, questionImage: Data, solutionImage: Data? = nil, createdDate: Date = .now) {
        self.problemSet = problemSet
        self.questionImage = questionImage
        self.solutionImage = solutionImage
        self.createdDate = createdDate
    }

    static func < (lhs: ImageProblem, rhs: ImageProblem) -> Bool {
        lhs.createdDate < rhs.createdDate
    }

    var description: String {
        return "Problem(created: \(createdDate), attempts: \(attempts.count), difficulty: \(currentDifficulty))"
    }

    var createdDate: Date

    var inInbox: Bool = false

    @Relationship
    var problemSet: ProblemSet

    @Relationship(deleteRule: .cascade, inverse: \Attempt.problem)
    var attempts: [Attempt] = []

    var attempted: Bool {
        !attempts.isEmpty
    }

    var currentDifficulty: Difficulty {
        guard let latest = attempts.max(by: { $0.createdDate < $1.createdDate }) else {
            return .notAttempted
        }
        return latest.difficulty
    }

    var lastAttempted: Date? {
        guard let latest = attempts.max(by: { $0.createdDate < $1.createdDate }) else { return nil }
        return latest.createdDate
    }
}
