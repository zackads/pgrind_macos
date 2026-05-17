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

    var problems: [ImageProblem] {
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

    var attempted: [ImageProblem] {
        var attempted: [ImageProblem] = []

        for ps in problemSets {
            for problem in ps.problems {
                if problem.attempted {
                    attempted.append(problem)
                }
            }
        }

        return attempted
    }

    var unattempted: [ImageProblem] {
        var unattempted: [ImageProblem] = []

        for ps in problemSets {
            for problem in ps.problems {
                if !problem.attempted {
                    unattempted.append(problem)
                }
            }
        }

        return unattempted
    }

    /// A rating between 0 and 1 of how difficult the course is, derived from Attempts of its Problems.
    var difficulty: Double {
        // A Course with no attempts is assumed to be of Medium difficulty
        guard !attempted.isEmpty else { return 0.5 }

        var countEasy = 0
        var countMedium = 0
        var countHard = 0
        var countNotAttempted = 0

        for problem in attempted {
            switch problem.currentDifficulty {
            case .easy: countEasy += 1
            case .medium: countMedium += 1
            case .hard: countHard += 1
            case .notAttempted: countNotAttempted += 1
            }
        }

        let weighted = 0.0 * Double(countEasy) + 0.5 * Double(countMedium) + 1.0 * Double(countHard)
        return weighted / Double(attempted.count)
    }
}
