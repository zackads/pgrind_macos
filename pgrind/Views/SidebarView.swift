//
//  SidebarView.swift
//  pgrind
//
//  Created by Zack Adlington on 15/05/2026.
//

import SwiftData
import SwiftUI

struct SidebarView: View {
    @Binding var selectedSidebarItem: Home.SidebarItem?
    let courses: [Course]
    let topics: [Topic]
    let studyPlans: [StudyPlan]
    let inboxCount: Int
    @Environment(\.modelContext) private var modelContext
    @State private var coursePendingDeletion: Course?
    @State private var showingDeleteConfirmation = false
    @State private var isHoveringCoursesHeader = false
    @State private var isHoveringStudyPlansHeader = false
    @State private var showingCreateCourse = false
    @State private var showingCreateStudyPlan = false
    @State private var studyPlanPendingDeletion: StudyPlan?
    @State private var showingDeleteStudyPlanConfirmation = false

    // Topic management
    @State private var topicPendingDeletion: Topic?
    @State private var showingDeleteTopicConfirmation = false
    @State private var renamingTopic: Topic?
    @State private var renameTopicText: String = ""
    @State private var showingCreateTopic = false
    @State private var newTopicName: String = ""
    /// When a topic is created via a course's "New Topic…" menu, assign it to this course on creation.
    @State private var courseAwaitingNewTopic: Course?

    private var ungroupedCourses: [Course] {
        courses.filter { $0.topic == nil }
    }

    private func courses(in topic: Topic) -> [Course] {
        courses.filter { $0.topic?.persistentModelID == topic.persistentModelID }
    }

    var body: some View {
        List(selection: $selectedSidebarItem) {
            inboxSection
            historySection
            ForEach(topics) { topic in
                topicSection(topic)
            }
            coursesSection
            studyPlansSection
        }
        .confirmationDialog(
            "Delete this course?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible,
            presenting: coursePendingDeletion
        ) { course in
            Button("Delete \"\(course.title)\" and all of its problems", role: .destructive) {
                modelContext.delete(course)
                if case let .course(selectedCourse) = selectedSidebarItem, selectedCourse.id == course.id {
                    selectedSidebarItem = nil
                }
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: { course in
            Text(
                "This will permanently delete the course \"\(course.title)\", " +
                    "all of its problems and any review data. This action cannot be undone."
            )
        }
        .confirmationDialog(
            "Delete this study plan?",
            isPresented: $showingDeleteStudyPlanConfirmation,
            titleVisibility: .visible,
            presenting: studyPlanPendingDeletion
        ) { plan in
            Button("Delete \"\(plan.name)\"", role: .destructive) {
                modelContext.delete(plan)
                if case let .studyPlan(selected) = selectedSidebarItem, selected.id == plan.id {
                    selectedSidebarItem = nil
                }
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: { plan in
            Text("This will permanently delete the study plan \"\(plan.name)\". This action cannot be undone.")
        }
        .confirmationDialog(
            "Delete this topic?",
            isPresented: $showingDeleteTopicConfirmation,
            titleVisibility: .visible,
            presenting: topicPendingDeletion
        ) { topic in
            Button("Delete \"\(topic.name)\"", role: .destructive) {
                modelContext.delete(topic)
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: { topic in
            Text(
                "This will delete the topic \"\(topic.name)\". Its courses will not be deleted — " +
                    "they'll become ungrouped."
            )
        }
        .alert("Rename Topic", isPresented: Binding(
            get: { renamingTopic != nil },
            set: { if !$0 { renamingTopic = nil } }
        )) {
            TextField("Name", text: $renameTopicText)
            Button("Cancel", role: .cancel) { renamingTopic = nil }
            Button("Rename") {
                let trimmed = renameTopicText.trimmingCharacters(in: .whitespacesAndNewlines)
                if let topic = renamingTopic, !trimmed.isEmpty {
                    topic.name = trimmed
                    try? modelContext.save()
                }
                renamingTopic = nil
            }
        }
        .alert("New Topic", isPresented: $showingCreateTopic) {
            TextField("Name", text: $newTopicName)
            Button("Cancel", role: .cancel) {
                newTopicName = ""
                courseAwaitingNewTopic = nil
            }
            Button("Create") {
                let trimmed = newTopicName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    let topic = Topic(name: trimmed)
                    modelContext.insert(topic)
                    if let course = courseAwaitingNewTopic {
                        course.topic = topic
                    }
                    try? modelContext.save()
                }
                newTopicName = ""
                courseAwaitingNewTopic = nil
            }
        }
        .sheet(isPresented: $showingCreateCourse) {
            CreateCourseSheet()
        }
        .sheet(isPresented: $showingCreateStudyPlan) {
            CreateStudyPlanSheet(topics: topics)
        }
    }

    private func topicSection(_ topic: Topic) -> some View {
        Section {
            ForEach(courses(in: topic)) { course in
                courseEntry(course)
            }
        } header: {
            HStack {
                Text(topic.name)
                Spacer()
            }
            .padding(.trailing, 8)
            .contentShape(Rectangle())
            .contextMenu {
                Button("Rename") {
                    renameTopicText = topic.name
                    renamingTopic = topic
                }
                Button(role: .destructive) {
                    topicPendingDeletion = topic
                    showingDeleteTopicConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var coursesSection: some View {
        Section {
            ForEach(ungroupedCourses) { course in
                courseEntry(course)
            }
            .onDeleteCommand {
                if case let .course(course) = selectedSidebarItem {
                    modelContext.delete(course)
                    selectedSidebarItem = nil
                    try? modelContext.save()
                }
            }
        } header: {
            coursesSectionHeader
        }
    }

    private func courseEntry(_ course: Course) -> some View {
        HStack {
            courseRow(course)
        }
        .tag(Home.SidebarItem.course(course))
        .contextMenu {
            Menu("Move to Topic") {
                ForEach(topics) { topic in
                    Button(topic.name) {
                        course.topic = topic
                        try? modelContext.save()
                    }
                }
                Divider()
                Button("New Topic…") {
                    courseAwaitingNewTopic = course
                    newTopicName = ""
                    showingCreateTopic = true
                }
                if course.topic != nil {
                    Divider()
                    Button("Remove from Topic") {
                        course.topic = nil
                        try? modelContext.save()
                    }
                }
            }
            Button(role: .destructive) {
                coursePendingDeletion = course
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var coursesSectionHeader: some View {
        HStack {
            Text("Courses")
            Spacer()
            Menu {
                Button("New Course") { showingCreateCourse = true }
                Button("New Topic…") {
                    courseAwaitingNewTopic = nil
                    newTopicName = ""
                    showingCreateTopic = true
                }
            } label: {
                Image(systemName: "plus")
                    .frame(width: 20, height: 20)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Add a course or topic")
            .opacity(isHoveringCoursesHeader ? 1 : 0)
            .allowsHitTesting(isHoveringCoursesHeader)
        }
        .padding(.trailing, 8)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHoveringCoursesHeader = hovering
        }
    }
}

extension SidebarView {
    var inboxSection: some View {
        Section {
            HStack(spacing: 8) {
                Image(systemName: "tray.full")
                Text("Inbox")
                    .fontWeight(.medium)
                Spacer()
                if inboxCount > 0 {
                    Text("\(inboxCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red, in: Capsule())
                }
            }
            .padding(.vertical, 4)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        selectedSidebarItem == .inbox
                            ? Color.accentColor
                            : Color.accentColor.opacity(inboxCount > 0 ? 0.12 : 0)
                    )
                    .padding(.horizontal, 4)
            )
            .tag(Home.SidebarItem.inbox)
        }
    }

    var historySection: some View {
        Section {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                Text("History")
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.vertical, 4)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedSidebarItem == .history ? Color.accentColor : Color.clear)
                    .padding(.horizontal, 4)
            )
            .tag(Home.SidebarItem.history)
        }
    }

    var studyPlansSection: some View {
        Section {
            ForEach(studyPlans) { plan in
                HStack {
                    studyPlanRow(plan)
                }
                .tag(Home.SidebarItem.studyPlan(plan))
                .contextMenu {
                    Button {
                        plan.isPaused.toggle()
                        try? modelContext.save()
                    } label: {
                        Label(
                            plan.isPaused ? "Resume" : "Pause",
                            systemImage: plan.isPaused ? "play.circle" : "pause.circle"
                        )
                    }
                    Button(role: .destructive) {
                        studyPlanPendingDeletion = plan
                        showingDeleteStudyPlanConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onDeleteCommand {
                if case let .studyPlan(plan) = selectedSidebarItem {
                    modelContext.delete(plan)
                    selectedSidebarItem = nil
                    try? modelContext.save()
                }
            }
        } header: {
            sectionHeader(
                title: "Study Plans",
                help: "Add a new study plan",
                isHovering: $isHoveringStudyPlansHeader,
                onAdd: { showingCreateStudyPlan = true }
            )
        }
    }

    func sectionHeader(
        title: String,
        help: String,
        isHovering: Binding<Bool>,
        onAdd: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help(help)
            .opacity(isHovering.wrappedValue ? 1 : 0)
            .allowsHitTesting(isHovering.wrappedValue)
        }
        .padding(.trailing, 8)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering.wrappedValue = hovering
        }
    }

    func courseRow(_ course: Course) -> some View {
        HStack {
            Text(course.title)
            Spacer()
            Pill(text: "\(Int(course.progress.proportionAttempted * 100))%")
        }
    }

    func studyPlanRow(_ plan: StudyPlan) -> some View {
        HStack {
            Image(systemName: plan.isPaused ? "pause.circle" : "calendar")
            Text(plan.name)
                .italic(plan.isPaused)
                .foregroundStyle(plan.isPaused ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
            Spacer()
        }
    }
}
