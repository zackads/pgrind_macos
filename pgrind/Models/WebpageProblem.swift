import Foundation
import SwiftData

@available(macOS 26.0, *)
@Model
final class WebpageProblem: Problem {
    var name: String
    var questionURL: String
    var solutionURL: String

    init(problemSet: ProblemSet, name: String, questionURL: String, solutionURL: String, createdDate: Date = .now) {
        self.name = name
        self.questionURL = questionURL
        self.solutionURL = solutionURL
        super.init(problemSet: problemSet, createdDate: createdDate)
    }
}
