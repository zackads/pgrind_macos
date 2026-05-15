//
//  SidebarView.swift
//  pgrind
//
//  Created by Zack Adlington on 15/05/2026.
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selectedSidebarItem: BrowseView.SidebarItem?
    let courses: [Course]
    @Environment(\.modelContext) private var modelContext
    @State private var coursePendingDeletion: Course? = nil
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        Group {
            List(selection: $selectedSidebarItem) {
                Section {
                    ForEach(courses) { course in
                        HStack {
                            Text(course.title)
                        }
                        .tag(BrowseView.SidebarItem.course(course))
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
                    Label("Courses", systemImage: "books.vertical")
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
    }
}
