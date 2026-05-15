//
//  SchemaV2.swift
//  pgrind
//
//  Removes WebpageProblem from the schema.
//

import Foundation
import SwiftData

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            Attempt.self,
            Course.self,
            ImageProblem.self,
            Problem.self,
            ProblemSet.self,
            ScreenshotItem.self,
        ]
    }
}
