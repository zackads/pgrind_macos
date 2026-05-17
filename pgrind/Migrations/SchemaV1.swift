//
//  SchemaV1.swift
//  pgrind
//

import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            Course.self,
            ProblemSet.self,
            ImageProblem.self,
            Attempt.self,
            ScreenshotItem.self,
            StudyPlan.self
        ]
    }
}
