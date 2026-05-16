//
//  StudyPlanView.swift
//  pgrind
//

import SwiftData
import SwiftUI

struct StudyPlanView: View {
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
        .formStyle(.grouped)
        .navigationTitle(studyPlan.name)
    }
}
