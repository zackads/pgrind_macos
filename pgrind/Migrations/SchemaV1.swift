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
    
    @Model
    final class Course {
        var title: String   // e.g. "18.100A | Real Analysis | Fall 2020"
        var summary: String
        var hyperlink: String     // e.g. https://ocw.mit.edu/courses/18-100a-real-analysis-fall-2020/
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
    }
    
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

    @Model
    class Problem {
        var createdDate: Date
        
        @Relationship
        var problemSet: ProblemSet
        
        @Relationship(deleteRule: .cascade, inverse: \Attempt.problem)
        var attempts: [Attempt] = []
        
        init(problemSet: ProblemSet, createdDate: Date = Date()) {
            self.problemSet = problemSet
            self.createdDate = createdDate
        }
        
        var currentDifficulty: Difficulty {
            guard let latest = attempts.max(by: {$0.createdDate < $1.createdDate }) else {
                return .notAttempted
            }
            return latest.difficulty
        }
        
        var lastAttempted: Date? {
            guard let latest = attempts.max(by: {$0.createdDate < $1.createdDate }) else { return nil }
            return latest.createdDate
        }
    }

    
    @Model
    final class ProblemSet {
        var name: String // e.g. "Week 1", "2023 past paper", "Chapter 12"
        
        @Relationship
        var course: Course
        
        var createdDate: Date = Date()
        
        @Relationship(deleteRule: .cascade, inverse: \Problem.problemSet)
        var problems: [Problem] = []
        
        init(course: Course, name: String) {
            self.course = course
            self.name = name
        }
    }

    @Model
    final class ScreenshotItem {
        var timestamp: Date
        
        @Attribute(.externalStorage)
        var pngData: Data
        
        init(timestamp: Date = .now, pngData: Data) {
            self.timestamp = timestamp
            self.pngData = pngData
        }
    }

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
}
