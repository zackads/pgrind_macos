//
//  StudyPlan.swift
//  pgrind
//
//  Created by Zack Adlington on 16/05/2026.
//

import SwiftData
import Foundation

@Model
class StudyPlan {
    /// e.g. sdf 'The Daily Q'
    var name: String
    /// The Courses from which Problems should be selected at the point of triggering
    var courses: [Course]
    var createdDate: Date = Date()

    /// How many Courses to select per trigger
    var courseCountPerTrigger: Int
    /// How many Problems to select per trigger
    var problemCountPerTrigger: Int

    // SwiftData can't introspect enum cases that contain Set/Dictionary/PersistentIdentifier
    // associated values, so the schedule and selection methods are stored as JSON blobs.
    private var scheduleData: Data
    private var courseSelectionMethodData: Data
    private var problemSelectionMethodData: Data

    var schedule: StudySchedule {
        get { (try? JSONDecoder().decode(StudySchedule.self, from: scheduleData)) ?? .daily(hour: 6, minute: 0) }
        set { scheduleData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var courseSelectionMethod: CourseSelectionMethod {
        get { (try? JSONDecoder().decode(CourseSelectionMethod.self, from: courseSelectionMethodData)) ?? .uniformRandom }
        set { courseSelectionMethodData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var problemSelectionMethod: ProblemSelectionMethod {
        get { (try? JSONDecoder().decode(ProblemSelectionMethod.self, from: problemSelectionMethodData)) ?? .uniform }
        set { problemSelectionMethodData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    init(name: String, courses: [Course], schedule: StudySchedule, courseCountPerTrigger: Int, courseSelectionMethod: CourseSelectionMethod, problemsPerCourse: Int, problemSelectionMethod: ProblemSelectionMethod) {
        self.name = name
        self.courses = courses
        self.courseCountPerTrigger = courseCountPerTrigger
        self.problemCountPerTrigger = problemsPerCourse
        self.scheduleData = (try? JSONEncoder().encode(schedule)) ?? Data()
        self.courseSelectionMethodData = (try? JSONEncoder().encode(courseSelectionMethod)) ?? Data()
        self.problemSelectionMethodData = (try? JSONEncoder().encode(problemSelectionMethod)) ?? Data()
    }
}

enum CourseSelectionMethod: Codable, Hashable, CustomStringConvertible, Identifiable, CaseIterable {
    case all
    case uniformRandom
    case weighted([PersistentIdentifier:Double])
    case fewestAttempts
    case greatestDifficulty
    
    var id: String { description }
    
    var description: String {
        switch self {
        case .all: "Include problems from each course."
        case .uniformRandom: "Select course(s) uniformly at random."
        case .weighted: "Select course(s) according to a given probability distribution."
        case .fewestAttempts: "Select the course(s) with the fewest attempts."
        case .greatestDifficulty: "Select the course(s) with the greatest overall difficulty."
        }
    }
    
    static var allCases: [CourseSelectionMethod] {
        [.all, .uniformRandom, .weighted([:]), .fewestAttempts, .greatestDifficulty]
    }
    
    func select(n: Int, from courses: [Course]) -> [Course] {
        switch self {
        case .all:
            // If the user selects .all, ignore n and return all Courses
            return courses
        case .uniformRandom:
            return Array(courses.shuffled().prefix(n))
        case .weighted(let weights):
            guard let pick = courses.weightedRandomElement({ weights[$0.persistentModelID] ?? 0 }) else { return [] }
            return [pick]
        case .fewestAttempts:
            return Array(courses.sorted(by: { $0.attempted.count < $1.attempted.count }).prefix(n))
        case .greatestDifficulty:
            return Array(courses.sorted(by: { $0.difficulty > $1.difficulty }).prefix(n))
        }
    }
}

enum ProblemSelectionMethod: Codable, Hashable, CustomStringConvertible {
    case uniform
    case unattempted
    case difficulties(Set<Difficulty>)
    case unattemptedBiasedEarlier(decay: Double)
    
    var description: String {
        switch self {
        case .uniform: "Select uniformly at random from all problems."
        case .unattempted: "Select uniformly at random from problems that haven't been attempted."
        case .difficulties(let difficulties): "Select uniformly at random from problems with selected difficulties."
        case .unattemptedBiasedEarlier: "Select uniformly at random from all problems that haven't been attempted, with bias towards those earlier in the course."
        }
    }
    
    func select(n: Int, from course: Course) -> [ImageProblem] {
        // TODO: Need to alert the user when selection failed, rather than silently falling back to random selection?
        switch self {
        case .uniform:
            return Array(course.problems.shuffled().prefix(n))
        case .unattempted:
            guard !course.unattempted.isEmpty else { return Array(course.problems.shuffled().prefix(n)) } // Fall back to uniform random selection
            return Array(course.unattempted.shuffled().prefix(n))
        case .difficulties(let difficulties):
            let candidates = course.problems.filter { difficulties.contains($0.currentDifficulty) }
            guard !candidates.isEmpty else { return Array(course.problems.shuffled().prefix(n)) } // Fall back to uniform random selection
            return Array(candidates.shuffled().prefix(n))
        case .unattemptedBiasedEarlier(let decay):
            guard !course.unattempted.isEmpty else { return Array(course.problems.shuffled().prefix(n)) }
            
            // Exponential decay
            let weighted: [(ImageProblem, Double)] = course.unattempted.enumerated().map { offset, problem in
                (problem, pow(decay, Double(offset)))
            }
            
            var selected: [ImageProblem] = []
            var remaining = weighted
            for _ in 0..<min(n, remaining.count) {
                if let pick = remaining.weightedRandomElement({ $0.1 }) {
                    selected.append(pick.0)
                    remaining.removeAll { $0.0.id == pick.0.id }
                }
            }
            return selected
        }
    }
}

extension BidirectionalCollection {
    func weightedRandomElement(_ weights: [Element: Double]) -> Element? where Element: Hashable {
        weightedRandomElement { weights[$0] ?? 0 }
    }

    func weightedRandomElement(_ weight: (Element) -> Double) -> Element? {
        let total = reduce(0) { $0 + weight($1) }
        guard total > 0 else { return nil }
        var roll = Double.random(in: 0..<total)
        for element in self {
            roll -= weight(element)
            if roll < 0 { return element }
        }
        return last
    }
}
