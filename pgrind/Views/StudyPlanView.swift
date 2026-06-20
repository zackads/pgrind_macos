//
//  StudyPlanView.swift
//  pgrind
//

import SwiftData
import SwiftUI

struct StudyPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var studyPlan: StudyPlan
    @Query(sort: \Course.title) private var allCourses: [Course]

    @State private var scheduleKind: ScheduleKind = .daily
    @State private var weekday: StudySchedule.Weekday = .monday
    @State private var timeOfDay: Date = .init()

    @State private var courseSelectionKind: CourseSelectionKind = .uniformRandom
    @State private var problemSelectionKind: ProblemSelectionKind = .uniform
    @State private var selectedDifficulties: Set<Difficulty> = Set(Difficulty.allCases)
    @State private var unattemptedDecay: Double = 0.9

    private enum ScheduleKind: String, CaseIterable, Identifiable {
        case daily, weekly
        var id: String {
            rawValue
        }

        var label: String {
            switch self {
            case .daily: "Daily"
            case .weekly: "Weekly"
            }
        }
    }

    private enum CourseSelectionKind: String, CaseIterable, Identifiable {
        case all, uniformRandom, fewestAttempts, greatestDifficulty
        var id: String {
            rawValue
        }

        var label: String {
            switch self {
            case .all: "Include all selected"
            case .uniformRandom: "Uniform random"
            case .fewestAttempts: "Fewest attempts"
            case .greatestDifficulty: "Greatest difficulty"
            }
        }
    }

    private enum ProblemSelectionKind: String, CaseIterable, Identifiable {
        case uniform, unattempted, difficulties, unattemptedBiasedEarlier
        var id: String {
            rawValue
        }

        var label: String {
            switch self {
            case .uniform: "Uniform random"
            case .unattempted: "Unattempted"
            case .difficulties: "By difficulty"
            case .unattemptedBiasedEarlier: "Unattempted, earlier-biased"
            }
        }
    }

    /// Distinct topics among the available courses, in stable order.
    private var topics: [Topic] {
        var seen = Set<PersistentIdentifier>()
        var result: [Topic] = []
        for course in allCourses {
            if let topic = course.topic, !seen.contains(topic.persistentModelID) {
                seen.insert(topic.persistentModelID)
                result.append(topic)
            }
        }
        return result
    }

    private func courses(in topic: Topic) -> [Course] {
        allCourses.filter { $0.topic?.persistentModelID == topic.persistentModelID }
    }

    private var ungroupedCourses: [Course] {
        allCourses.filter { $0.topic == nil }
    }

    private func isSelected(_ course: Course) -> Bool {
        studyPlan.courses.contains { $0.persistentModelID == course.persistentModelID }
    }

    private func setSelected(_ course: Course, _ isOn: Bool) {
        if isOn {
            if !isSelected(course) { studyPlan.courses.append(course) }
        } else {
            studyPlan.courses.removeAll { $0.persistentModelID == course.persistentModelID }
        }
    }

    private func courseToggle(_ course: Course) -> some View {
        Toggle(course.title, isOn: Binding(
            get: { isSelected(course) },
            set: { setSelected(course, $0) }
        ))
    }

    /// A "select all" toggle for a topic — snapshot semantics: on when every course
    /// currently in the topic is selected; toggling adds/removes them all.
    private func topicSelectionBinding(_ topic: Topic) -> Binding<Bool> {
        Binding(
            get: {
                let inTopic = courses(in: topic)
                return !inTopic.isEmpty && inTopic.allSatisfy { isSelected($0) }
            },
            set: { isOn in
                for course in courses(in: topic) {
                    setSelected(course, isOn)
                }
            }
        )
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $studyPlan.name, prompt: Text("E.g. 'The Daily Q'"))
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
                if allCourses.isEmpty {
                    Text("No courses available")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(topics) { topic in
                        Toggle(isOn: topicSelectionBinding(topic)) {
                            Text(topic.name).fontWeight(.semibold)
                        }
                        ForEach(courses(in: topic)) { course in
                            courseToggle(course)
                                .padding(.leading, 16)
                        }
                    }
                    ForEach(ungroupedCourses) { course in
                        courseToggle(course)
                    }
                }
            }

            Section("Selection") {
                Stepper(
                    "Problems per trigger: \(studyPlan.problemCountPerTrigger)",
                    value: $studyPlan.problemCountPerTrigger,
                    in: 1 ... 20
                )
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
                        Slider(value: $unattemptedDecay, in: 0.5 ... 0.99, step: 0.01)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    studyPlan.isPaused ? "Resume" : "Pause",
                    systemImage: studyPlan.isPaused ? "play.circle" : "pause.circle"
                ) {
                    studyPlan.isPaused.toggle()
                    try? modelContext.save()
                }
                .help(studyPlan.isPaused ? "Resume this study plan" : "Pause this study plan")
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Run", systemImage: "play.fill") {
                    runStudyPlan()
                }
                .disabled(studyPlan.isPaused)
                .help("Run")
            }
        }
        .formStyle(.grouped)
        .navigationTitle(studyPlan.name)
        .onAppear(perform: loadFromModel)
        .onChange(of: scheduleKind) { _, _ in writeSchedule() }
        .onChange(of: weekday) { _, _ in writeSchedule() }
        .onChange(of: timeOfDay) { _, _ in writeSchedule() }
        .onChange(of: courseSelectionKind) { _, _ in writeCourseSelectionMethod() }
        .onChange(of: problemSelectionKind) { _, _ in writeProblemSelectionMethod() }
        .onChange(of: selectedDifficulties) { _, _ in
            if problemSelectionKind == .difficulties { writeProblemSelectionMethod() }
        }
        .onChange(of: unattemptedDecay) { _, _ in
            if problemSelectionKind == .unattemptedBiasedEarlier { writeProblemSelectionMethod() }
        }
        .onDisappear {
            try? modelContext.save()
        }
    }
}

extension StudyPlanView {
    func loadFromModel() {
        switch studyPlan.schedule {
        case let .daily(hour, minute):
            scheduleKind = .daily
            timeOfDay = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        case let .weekly(day, hour, minute):
            scheduleKind = .weekly
            weekday = day
            timeOfDay = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        }

        switch studyPlan.courseSelectionMethod {
        case .all: courseSelectionKind = .all
        case .uniformRandom, .weighted: courseSelectionKind = .uniformRandom
        case .fewestAttempts: courseSelectionKind = .fewestAttempts
        case .greatestDifficulty: courseSelectionKind = .greatestDifficulty
        }

        switch studyPlan.problemSelectionMethod {
        case .uniform:
            problemSelectionKind = .uniform
        case .unattempted:
            problemSelectionKind = .unattempted
        case let .difficulties(difficulties):
            problemSelectionKind = .difficulties
            selectedDifficulties = difficulties
        case let .unattemptedBiasedEarlier(decay):
            problemSelectionKind = .unattemptedBiasedEarlier
            unattemptedDecay = decay
        }
    }

    func writeSchedule() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: timeOfDay)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        switch scheduleKind {
        case .daily:
            studyPlan.schedule = .daily(hour: hour, minute: minute)
        case .weekly:
            studyPlan.schedule = .weekly(weekday: weekday, hour: hour, minute: minute)
        }
    }

    private func writeCourseSelectionMethod() {
        switch courseSelectionKind {
        case .all: studyPlan.courseSelectionMethod = .all
        case .uniformRandom: studyPlan.courseSelectionMethod = .uniformRandom
        case .fewestAttempts: studyPlan.courseSelectionMethod = .fewestAttempts
        case .greatestDifficulty: studyPlan.courseSelectionMethod = .greatestDifficulty
        }
    }

    private func writeProblemSelectionMethod() {
        switch problemSelectionKind {
        case .uniform: studyPlan.problemSelectionMethod = .uniform
        case .unattempted: studyPlan.problemSelectionMethod = .unattempted
        case .difficulties: studyPlan.problemSelectionMethod = .difficulties(selectedDifficulties)
        case .unattemptedBiasedEarlier:
            studyPlan.problemSelectionMethod = .unattemptedBiasedEarlier(decay: unattemptedDecay)
        }
    }

    private func runStudyPlan() {
        studyPlan.run()
        try? modelContext.save()
    }
}
