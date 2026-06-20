//
//  Topic.swift
//  pgrind
//

import Foundation
import SwiftData

/// A grouping of related `Course`s, e.g. "Linear Algebra" containing several
/// linear algebra courses from different institutions.
@Model
final class Topic {
    var name: String
    var createdDate: Date = Date()

    /// Deleting a Topic must not delete its Courses — they simply become ungrouped.
    @Relationship(deleteRule: .nullify, inverse: \Course.topic)
    var courses: [Course] = []

    init(name: String) {
        self.name = name
    }
}
