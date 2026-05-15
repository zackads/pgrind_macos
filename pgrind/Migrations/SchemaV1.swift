//
//  PgrindSchemaV1.swift
//  pgrind
//
//  Created by Zack Adlington on 21/02/2026.
//

import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [
        Attempt.self,
        Course.self,
        ImageProblem.self,
        Problem.self,
        ProblemSet.self,
        ScreenshotItem.self,
        WebpageProblem.self
    ] }
}

@available(macOS 26.0, *)
@Model
final class WebpageProblem: Problem {
    var name: String
    var questionURL: String
    var solutionURL: String

    init(problemSet: ProblemSet, name: String, questionURL: String, solutionURL: String, createdDate: Date = .now) {
        self.questionURL = questionURL
        self.solutionURL = solutionURL
        self.name = name
        super.init(problemSet: problemSet, createdDate: createdDate)
    }
}
