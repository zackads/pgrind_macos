import Foundation
import SwiftData

@Model
final class Attempt {
    @Relationship
    var problem: ImageProblem

    var createdDate: Date
    var difficulty: Difficulty
    var notes: String?

    init(problem: ImageProblem, difficulty: Difficulty, timestamp: Date = .now, notes: String? = nil) {
        self.problem = problem
        createdDate = timestamp
        self.difficulty = difficulty
        if let notes {
            let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { self.notes = notes }
        }
    }
}
