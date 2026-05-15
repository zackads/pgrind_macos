import Foundation
import SwiftData

/// A snapshot of a learner's progress through a `Course`'s problems.
///
/// Both values are fractions in the range `0...1` (not 0–100).
struct Progress {
    /// Fraction of the course's problems that have at least one recorded attempt.
    var proportionAttempted: Float
    /// Fraction of the course's problems whose most recent attempt was rated `.easy`.
    var proportionEasy: Float
}

@Model
final class Course {
    var title: String // e.g. "18.100A | Real Analysis | Fall 2020"
    var summary: String
    var hyperlink: String // e.g. https://ocw.mit.edu/courses/18-100a-real-analysis-fall-2020/
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

    /// Aggregate progress across every problem in the course.
    var progress: Progress {
        guard !problems.isEmpty else {
            return Progress(proportionAttempted: 0, proportionEasy: 0)
        }

        return Progress(
            proportionAttempted: Float(problems.filter { $0.attempted }.count) / Float(problems.count),
            proportionEasy: Float(problems.filter { $0.currentDifficulty == .easy }.count) / Float(problems.count)
        )
    }
}
