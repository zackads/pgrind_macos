//
//  CreateStudyPlanSheet.swift
//  pgrind
//

import SwiftData
import SwiftUI

struct CreateStudyPlanSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let courses: [Course]

    @State private var name: String = ""
    @State private var scheduleKind: ScheduleKind = .daily
    @State private var weekday: StudySchedule.Weekday = .monday
    @State private var timeOfDay: Date = Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var selectedCourseIDs: Set<PersistentIdentifier> = []
    @State private var courseCountPerTrigger: Int = 1
    @State private var problemsPerCourse: Int = 3
    @State private var courseSelectionMethod: CourseSelectionMethod = .uniformRandom
    @State private var problemSelectionKind: ProblemSelectionKind = .uniform
    @State private var selectedDifficulties: Set<Difficulty> = Set(Difficulty.allCases)
    @State private var unattemptedDecay: Double = 0.9

    private enum ScheduleKind: String, CaseIterable, Identifiable {
        case daily, weekly
        var id: String { rawValue }
        var label: String {
            switch self {
            case .daily: "Daily"
            case .weekly: "Weekly"
            }
        }
    }

    private enum ProblemSelectionKind: String, CaseIterable, Identifiable {
        case uniform, unattempted, difficulties, unattemptedBiasedEarlier
        var id: String { rawValue }
        var label: String {
            switch self {
            case .uniform: "Uniform random"
            case .unattempted: "Unattempted"
            case .difficulties: "By difficulty"
            case .unattemptedBiasedEarlier: "Unattempted, earlier-biased"
            }
        }
    }

    private var courseSelectionLabel: (CourseSelectionMethod) -> String {
        { method in
            switch method {
            case .all: "Include all selected"
            case .uniformRandom: "Uniform random"
            case .weighted: "Weighted"
            case .fewestAttempts: "Fewest attempts"
            case .greatestDifficulty: "Greatest difficulty"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField(text: $name, prompt: Text("E.g. 'The Daily Q'")) {
                        Text("Name")
                    }
                }

                Section("Schedule") {
                    Picker("Frequency", selection: $scheduleKind) {
                        ForEach(ScheduleKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    if scheduleKind == .weekly {
                        Picker("Weekday", selection: $weekday) {
                            ForEach(StudySchedule.Weekday.allCases, id: \.self) { day in
                                Text(day.description).tag(day)
                            }
                        }
                    }
                    DatePicker("Time", selection: $timeOfDay, displayedComponents: .hourAndMinute)
                }

                Section("Courses") {
                    if courses.isEmpty {
                        Text("No courses available. Create a course first.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(courses) { course in
                            Toggle(course.title, isOn: Binding(
                                get: { selectedCourseIDs.contains(course.persistentModelID) },
                                set: { isOn in
                                    if isOn {
                                        selectedCourseIDs.insert(course.persistentModelID)
                                    } else {
                                        selectedCourseIDs.remove(course.persistentModelID)
                                    }
                                }
                            ))
                        }
                    }
                }
                .onAppear {
                    if selectedCourseIDs.isEmpty {
                        selectedCourseIDs = Set(courses.map(\.persistentModelID))
                    }
                }

                Section("Problems per course") {
                    HStack {
                        Text("Problems per course: \(problemsPerCourse)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Slider(
                            value: Binding(
                                get: { Double(problemsPerCourse) },
                                set: { problemsPerCourse = max(1, Int($0)) }
                            ),
                            in: 0...5,
                            step: 1
                        )
                    }
                    Picker("Problem selection", selection: $problemSelectionKind) {
                        ForEach(ProblemSelectionKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    if problemSelectionKind == .difficulties {
                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            Toggle(difficulty.description, isOn: Binding(
                                get: { selectedDifficulties.contains(difficulty) },
                                set: { isOn in
                                    if isOn {
                                        selectedDifficulties.insert(difficulty)
                                    } else {
                                        selectedDifficulties.remove(difficulty)
                                    }
                                }
                            ))
                        }
                    }
                    if problemSelectionKind == .unattemptedBiasedEarlier {
                        HStack {
                            Text("Decay: \(String(format: "%.2f", unattemptedDecay))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Slider(value: $unattemptedDecay, in: 0.5...0.99, step: 0.01)
                        }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("Create") {
                    let components = Calendar.current.dateComponents([.hour, .minute], from: timeOfDay)
                    let hour = components.hour ?? 0
                    let minute = components.minute ?? 0
                    let schedule: StudySchedule = {
                        switch scheduleKind {
                        case .daily: return .daily(hour: hour, minute: minute)
                        case .weekly: return .weekly(on: weekday, hour: hour, minute: minute)
                        }
                    }()
                    let selectedCourses = courses.filter { selectedCourseIDs.contains($0.persistentModelID) }
                    let problemSelectionMethod: ProblemSelectionMethod = {
                        switch problemSelectionKind {
                        case .uniform: return .uniform
                        case .unattempted: return .unattempted
                        case .difficulties: return .difficulties(selectedDifficulties)
                        case .unattemptedBiasedEarlier: return .unattemptedBiasedEarlier(decay: unattemptedDecay)
                        }
                    }()
                    let plan = StudyPlan(
                        name: name,
                        courses: selectedCourses,
                        schedule: schedule,
                        courseCountPerTrigger: selectedCourseIDs.count,
                        courseSelectionMethod: .all,
                        problemsPerCourse: problemsPerCourse,
                        problemSelectionMethod: problemSelectionMethod
                    )
                    modelContext.insert(plan)
                    try? modelContext.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 520, minHeight: 480)
        .navigationTitle("Create a new study plan")
    }
}
