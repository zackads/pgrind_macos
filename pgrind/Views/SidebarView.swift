//
//  SidebarView.swift
//  pgrind
//
//  Created by Zack Adlington on 15/05/2026.
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selectedSidebarItem: Home.SidebarItem?
    let courses: [Course]
    @Environment(\.modelContext) private var modelContext
    @State private var coursePendingDeletion: Course? = nil
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
                        if case .course(let course) = selectedSidebarItem {
                            modelContext.delete(course)
                            selectedSidebarItem = nil
                            try? modelContext.save()
                        }
                    }
                } header: {
                    HStack {
                        Label("Courses", systemImage: "books.vertical")
                        Spacer()
                        Button {
                            showingCreateCourse = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)
                        .help("Add a new course")
                        .opacity(isHoveringCoursesHeader ? 1 : 0)
                    }
//                    .contentShape(Rectangle())
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
            presenting: coursePendingDeletion,
        ) { course in
            Button("Delete \"\(course.title)\" and all of its problems", role: .destructive) {
                modelContext.delete(course)
                if case .course(let selectedCourse) = selectedSidebarItem, selectedCourse.id == course.id {
                    selectedSidebarItem = nil
                }
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) { }
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

private struct CreateCourseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var summary: String = ""
    @State private var hyperlink: String = ""

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedSummary: String { summary.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedHyperlink: String { hyperlink.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField(text: $title, prompt: Text("E.g. 'MIT 18.01 | Single Variable Calculus | Fall 2020'")) {
                    Text("Name")
                }
                TextField(text: $summary, prompt: Text("E.g. 'Master the calculus of derivatives, integrals, coordinate systems, and infinite series.'"), axis: .vertical) {
                    Text("Description")
                }
                .lineLimit(3...5)
                TextField(text: $hyperlink, prompt: Text("E.g. 'https://ocw.mit.edu/courses/18-01-calculus-i-single-variable-calculus-fall-2020/'")) {
                    Text("Website URL")
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
                    let newCourse = Course(
                        title: trimmedTitle,
                        summary: trimmedSummary,
                        hyperlink: trimmedHyperlink
                    )
                    modelContext.insert(newCourse)
                    try? modelContext.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(trimmedTitle.isEmpty || trimmedSummary.isEmpty || trimmedHyperlink.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 480, minHeight: 320)
        .navigationTitle("Create a new course")
    }
}
