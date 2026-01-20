import Foundation
import SwiftData

@Model
final class Attempt {
    @Relationship
    var problem: Problem
    
    var createdDate: Date
    var difficulty: Difficulty
    var notes: String?
    
    init(problem: Problem, difficulty: Difficulty, timestamp: Date = .now, notes: String? = nil) {
        self.problem = problem
        self.createdDate = timestamp
        self.difficulty = difficulty
        if let notes {
            let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { self.notes = notes }
        }
    }
}
