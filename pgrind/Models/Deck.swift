//
//  Deck.swift
//  pgrind
//
//  Created by Zack Adlington on 01/04/2026.
//

import Foundation
import SwiftData

@Model
final class Deck {
    var title: String // e.g. "Summer 2026 exams"
    var createdDate: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \ProblemSet.course)
    var problemSets: [ProblemSet] = []

    var problems: [Problem] {
        return problemSets.flatMap(\.problems)
    }

    init(title: String, problemSets: [ProblemSet]) {
        self.title = title
        self.problemSets = problemSets
    }
}
