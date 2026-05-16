//
//  StudyPlanView.swift
//  pgrind
//

import SwiftData
import SwiftUI

struct StudyPlanView: View {
    @Environment(\.modelContext) private var modelContext
    let studyPlan: StudyPlan

    var body: some View {
        Form {
            Section("Schedule") {
                LabeledContent("When", value: studyPlan.schedule.description)
            }

            Section("Courses") {
                if studyPlan.courses.isEmpty {
                    Text("No courses selected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(studyPlan.courses) { course in
                        Text(course.title)
                    }
                }
            }

            Section("Selection") {
                LabeledContent("Courses per trigger", value: "\(studyPlan.courseCountPerTrigger)")
                LabeledContent("Course selection", value: studyPlan.courseSelectionMethod.description)
                LabeledContent("Problems per trigger", value: "\(studyPlan.problemCountPerTrigger)")
                LabeledContent("Problem selection", value: studyPlan.problemSelectionMethod.description)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Run", systemImage: "play.fill") {
                    runStudyPlan()
                }
                .help("Run")
            }
        }
        .formStyle(.grouped)
        .navigationTitle(studyPlan.name)
    }

    private func runStudyPlan() {
        let selectedCourses = studyPlan.courseSelectionMethod.select(
            n: studyPlan.courseCountPerTrigger,
            from: studyPlan.courses
        )
        for course in selectedCourses {
            let problems = studyPlan.problemSelectionMethod.select(
                n: studyPlan.problemCountPerTrigger,
                from: course
            )
            for problem in problems {
                problem.inInbox = true
            }
        }
        try? modelContext.save()
    }
}
