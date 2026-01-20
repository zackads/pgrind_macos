import Foundation
import SwiftData

@available(macOS 26.0, *)
@Model
final class ImageProblem: Problem {
    @Attribute(.externalStorage)
    var questionImage: Data
    @Attribute(.externalStorage)
    var solutionImage: Data?
    
    init(problemSet: ProblemSet, questionImage: Data, solutionImage: Data? = nil, createdDate: Date = .now) {
        self.questionImage = questionImage
        self.solutionImage = solutionImage
        super.init(problemSet: problemSet, createdDate: createdDate)
    }
}
