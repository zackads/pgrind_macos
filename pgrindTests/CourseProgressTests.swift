import Foundation
@testable import pgrind
import SwiftData
import Testing

@MainActor
struct CourseProgressTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Course.self,
            ProblemSet.self,
            ImageProblem.self,
            Attempt.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeCourse(
        in context: ModelContext,
        problemDifficulties: [Difficulty?]
    ) -> Course {
        let course = Course(title: "Test Course", summary: "", hyperlink: "")
        context.insert(course)
        let set = ProblemSet(course: course, name: "Set 1")
        context.insert(set)
        for difficulty in problemDifficulties {
            let problem = ImageProblem(problemSet: set, questionImage: Data())
            context.insert(problem)
            if let difficulty {
                let attempt = Attempt(problem: problem, difficulty: difficulty)
                context.insert(attempt)
            }
        }
        return course
    }

    @Test func emptyCourseReportsZeroProgress() throws {
        let container = try makeContainer()
        let course = Course(title: "Empty", summary: "", hyperlink: "")
        container.mainContext.insert(course)

        let progress = course.progress
        #expect(progress.proportionAttempted == 0)
        #expect(progress.proportionEasy == 0)
    }

    @Test func courseWithNoAttemptsReportsZeroAttempted() throws {
        let container = try makeContainer()
        let course = makeCourse(
            in: container.mainContext,
            problemDifficulties: [nil, nil, nil]
        )

        let progress = course.progress
        #expect(progress.proportionAttempted == 0)
        #expect(progress.proportionEasy == 0)
    }

    @Test func fullyAttemptedCourseReportsOne() throws {
        let container = try makeContainer()
        let course = makeCourse(
            in: container.mainContext,
            problemDifficulties: [.easy, .medium, .hard, .easy]
        )

        #expect(course.progress.proportionAttempted == 1.0)
    }

    @Test func proportionEasyCountsOnlyProblemsWhoseLatestAttemptIsEasy() throws {
        let container = try makeContainer()
        // 4 problems: 2 easy, 1 medium, 1 unattempted
        let course = makeCourse(
            in: container.mainContext,
            problemDifficulties: [.easy, .easy, .medium, nil]
        )

        let progress = course.progress
        #expect(progress.proportionEasy == 0.5)
        #expect(progress.proportionAttempted == 0.75)
    }

    @Test func proportionEasyUsesMostRecentAttempt() throws {
        let container = try makeContainer()
        let course = Course(title: "C", summary: "", hyperlink: "")
        container.mainContext.insert(course)
        let set = ProblemSet(course: course, name: "S")
        container.mainContext.insert(set)
        let problem = ImageProblem(problemSet: set, questionImage: Data())
        container.mainContext.insert(problem)

        let earlier = Date(timeIntervalSince1970: 1000)
        let later = Date(timeIntervalSince1970: 2000)
        container.mainContext.insert(
            Attempt(problem: problem, difficulty: .hard, timestamp: earlier)
        )
        container.mainContext.insert(
            Attempt(problem: problem, difficulty: .easy, timestamp: later)
        )

        #expect(course.progress.proportionEasy == 1.0)
    }

    @Test func progressAggregatesAcrossProblemSets() throws {
        let container = try makeContainer()
        let course = Course(title: "Multi", summary: "", hyperlink: "")
        container.mainContext.insert(course)

        let setA = ProblemSet(course: course, name: "A")
        let setB = ProblemSet(course: course, name: "B")
        container.mainContext.insert(setA)
        container.mainContext.insert(setB)

        let p1 = ImageProblem(problemSet: setA, questionImage: Data())
        let p2 = ImageProblem(problemSet: setB, questionImage: Data())
        container.mainContext.insert(p1)
        container.mainContext.insert(p2)
        container.mainContext.insert(Attempt(problem: p1, difficulty: .easy))

        let progress = course.progress
        #expect(progress.proportionAttempted == 0.5)
        #expect(progress.proportionEasy == 0.5)
    }
}
