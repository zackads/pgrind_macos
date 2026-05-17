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

    var body: some View {
        List(selection: $selectedSidebarItem) {
            inboxSection
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
            Text("This will permanently delete the course \"\(course.title)\", all of its problems and any review data. This action cannot be undone.")
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
        .sheet(isPresented: $showingCreateCourse) {
            CreateCourseSheet()
        }
        .sheet(isPresented: $showingCreateStudyPlan) {
            CreateStudyPlanSheet(courses: courses)
        }
    }

    private var inboxSection: some View {
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

    private var coursesSection: some View {
        Section {
            ForEach(courses) { course in
                HStack {
                    courseRow(course)
                }
                .tag(Home.SidebarItem.course(course))
                .contextMenu {
                    Button(role: .destructive) {
                        coursePendingDeletion = course
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onDeleteCommand {
                if case let .course(course) = selectedSidebarItem {
                    modelContext.delete(course)
                    selectedSidebarItem = nil
                    try? modelContext.save()
                }
            }
        } header: {
            sectionHeader(
                title: "Courses",
                help: "Add a new course",
                isHovering: $isHoveringCoursesHeader,
                onAdd: { showingCreateCourse = true }
            )
        }
    }

    private var studyPlansSection: some View {
        Section {
            ForEach(studyPlans) { plan in
                HStack {
                    studyPlanRow(plan)
                }
                .tag(Home.SidebarItem.studyPlan(plan))
                .contextMenu {
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

    private func sectionHeader(title: String, help: String, isHovering: Binding<Bool>, onAdd: @escaping () -> Void) -> some View {
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

    private func courseRow(_ course: Course) -> some View {
        return HStack {
            Text(course.title)
            Spacer()
            Pill(text: "\(Int(course.progress.proportionAttempted * 100))%")
        }
    }

    private func studyPlanRow(_ plan: StudyPlan) -> some View {
        HStack {
            Image(systemName: "calendar")
            Text(plan.name)
            Spacer()
        }
    }
}
