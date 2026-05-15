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
    @Environment(\.modelContext) private var modelContext
    @State private var coursePendingDeletion: Course?
    @State private var showingDeleteConfirmation = false
    @State private var isHoveringCoursesHeader = false
    @State private var showingCreateCourse = false

    var body: some View {
        Group {
            List(selection: $selectedSidebarItem) {
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
                    HStack {
                        Text("Courses")
                        Spacer()
                        Button {
                            showingCreateCourse = true
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.plain)
                        .help("Add a new course")
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
        .sheet(isPresented: $showingCreateCourse) {
            CreateCourseSheet()
        }
    }

    private func courseRow(_ course: Course) -> some View {
        return HStack {
            Text(course.title)
            Spacer()
            Pill(text: "\(Int(course.progress.proportionAttempted * 100))%")
        }
    }
}
