import AppKit
import SwiftData
import SwiftUI

struct Home: View {
    enum Route: Hashable {
        case viewCourse(Course)
        case recordAttempt(ImageProblem)
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    @Query(sort: \Course.createdDate, order: .forward) private var courses: [Course]
    @Query(sort: \ProblemSet.createdDate, order: .forward) private var problemSets: [ProblemSet]
    @Query(sort: \ImageProblem.createdDate, order: .forward) private var problems: [ImageProblem]
    @Query(
        filter: #Predicate<ImageProblem> { $0.inInbox },
        sort: \ImageProblem.createdDate,
        order: .forward
    ) private var inboxProblems: [ImageProblem]
    @Query(sort: \StudyPlan.createdDate, order: .forward) private var studyPlans: [StudyPlan]
    @Query(sort: \Topic.createdDate, order: .forward) private var topics: [Topic]

    @State private var path: [Route] = []

    enum SidebarItem: Hashable {
        case inbox
        case history
        case course(Course)
        case studyPlan(StudyPlan)
    }

    @State private var selectedSidebarItem: SidebarItem? = .inbox
    var selectedCourse: Course? {
        if case let .course(course) = selectedSidebarItem { return course }
        return nil
    }

    @State private var selectedProblem: ImageProblem?

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedSidebarItem: $selectedSidebarItem,
                courses: courses,
                topics: topics,
                studyPlans: studyPlans,
                inboxCount: inboxProblems.count
            )
        } detail: {
            NavigationStack(path: $path) {
                Group {
                    switch selectedSidebarItem {
                    case .inbox:
                        InboxView(path: $path, problems: inboxProblems)
                    case .history:
                        let recentlyAttempted = problems
                            .filter { $0.lastAttempted != nil }
                            .sorted { ($0.lastAttempted ?? .distantPast) > ($1.lastAttempted ?? .distantPast) }
                        ScrollView {
                            ProblemsGalleryView(problems: recentlyAttempted) { problem in
                                path.append(.recordAttempt(problem))
                            }
                        }
                        .navigationTitle("History")
                    case let .course(course):
                        CourseView(path: $path, course: course)
                    case let .studyPlan(studyPlan):
                        StudyPlanView(studyPlan: studyPlan)
                    case nil:
                        ContentUnavailableView("Select a course", systemImage: "books.vertical")
                    }
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case let .viewCourse(course):
                        CourseView(path: $path, course: course)
                    case let .recordAttempt(problem):
                        RecordAttemptView(path: $path, problem: problem)
                    }
                }
            }
        }
        .onChange(of: selectedSidebarItem) { _, _ in
            selectedProblem = nil
        }
    }
}
