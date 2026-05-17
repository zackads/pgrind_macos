//
//  CourseView.swift
//  pgrind
//
//  Created by Zack Adlington on 15/05/2026.
//

import SwiftData
import SwiftUI

struct CourseView: View {
    @Binding var path: [Home.Route]
    var course: Course

    @Environment(\.modelContext) private var modelContext
    @State private var showingAddProblemSet = false
    @State private var renamingProblemSet: ProblemSet?
    @State private var renameText: String = ""
    @State private var deletingProblemSet: ProblemSet?

    private var isRenaming: Binding<Bool> {
        Binding(
            get: { renamingProblemSet != nil },
            set: { if !$0 { renamingProblemSet = nil } }
        )
    }

    private var isDeleting: Binding<Bool> {
        Binding(
            get: { deletingProblemSet != nil },
            set: { if !$0 { deletingProblemSet = nil } }
        )
    }

    @ViewBuilder
    private func row(for ps: ProblemSet) -> some View {
        VStack(alignment: .leading) {
            Text(ps.name)
                .font(.title3)
            ProblemsGalleryView(
                problems: ps.sortedProblems,
                onSelect: { problem in
                    path.append(.viewProblem(problem))
                },
                onAdd: {
                    addProblem(to: ps)
                }
            )
        }
        .tag(ps)
        .contextMenu {
            Button("Rename") {
                renameText = ps.name
                renamingProblemSet = ps
            }
            Button("Delete", role: .destructive) {
                deletingProblemSet = ps
            }
        }
    }

    private func commitRename() {
        guard let ps = renamingProblemSet else { return }
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            ps.name = trimmed
        }
        renamingProblemSet = nil
    }

    private func addProblem(to problemSet: ProblemSet) {
        Task { @MainActor in
            guard let imageData = await Screenshotter.takeScreenshot() else { return }
            let problem = ImageProblem(
                problemSet: problemSet,
                questionImage: imageData
            )
            problemSet.problems.append(problem)
            do {
                try modelContext.save()
            } catch {
                print("Failed to save new problem: \(error)")
            }
        }
    }

    private func confirmDelete() {
        guard let ps = deletingProblemSet else { return }
        modelContext.delete(ps)
        deletingProblemSet = nil
    }

    var body: some View {
        List(course.problemSets) { ps in
            row(for: ps)
        }
        .navigationTitle(course.title)
        .toolbar {
            Button {
                showingAddProblemSet = true
            } label: {
                Label("Add problems", systemImage: "rectangle.stack.badge.plus")
            }
            .keyboardShortcut("n", modifiers: [.command])
            .labelStyle(.titleAndIcon)
        }
        .sheet(isPresented: $showingAddProblemSet) {
            AddProblemSetView(course: course)
        }
        .alert("Rename Problem Set", isPresented: isRenaming) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { renamingProblemSet = nil }
            Button("Rename", action: commitRename)
        }
        .confirmationDialog(
            "Delete this problem set? All problems in it will also be deleted.",
            isPresented: isDeleting,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: confirmDelete)
            Button("Cancel", role: .cancel) { deletingProblemSet = nil }
        }
    }
}
