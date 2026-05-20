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
    @State private var addingProblemTo: ProblemSet?
    @State private var collapsedProblemSets: Set<PersistentIdentifier> = []

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

    private func isExpanded(_ problemSet: ProblemSet) -> Binding<Bool> {
        Binding(
            get: { !collapsedProblemSets.contains(problemSet.persistentModelID) },
            set: { expanded in
                if expanded {
                    collapsedProblemSets.remove(problemSet.persistentModelID)
                } else {
                    collapsedProblemSets.insert(problemSet.persistentModelID)
                }
            }
        )
    }

    private func row(for problemSet: ProblemSet) -> some View {
        DisclosureGroup(isExpanded: isExpanded(problemSet)) {
            ProblemsGalleryView(
                problems: problemSet.sortedProblems,
                onSelect: { problem in
                    path.append(.viewProblem(problem))
                },
                onAdd: {
                    addingProblemTo = problemSet
                }
            )
        } label: {
            Text(problemSet.name)
                .font(.title3)
        }
        .tag(problemSet)
        .contextMenu {
            Button("Rename") {
                renameText = problemSet.name
                renamingProblemSet = problemSet
            }
            Button("Delete", role: .destructive) {
                deletingProblemSet = problemSet
            }
        }
    }

    private func commitRename() {
        guard let problemSet = renamingProblemSet else { return }
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            problemSet.name = trimmed
        }
        renamingProblemSet = nil
    }

    private func confirmDelete() {
        guard let problemSet = deletingProblemSet else { return }
        modelContext.delete(problemSet)
        deletingProblemSet = nil
    }

    var body: some View {
        List {
            Section {
                CourseHeatmap(problems: course.problems) { problem in
                    path.append(.viewProblem(problem))
                }
            }
            ForEach(course.problemSets) { problemSet in
                row(for: problemSet)
            }
        }
        .navigationTitle(course.title)
        .toolbar {
            let allCollapsed = !course.problemSets.isEmpty
                && course.problemSets.allSatisfy { collapsedProblemSets.contains($0.persistentModelID) }
            Button {
                if allCollapsed {
                    collapsedProblemSets.removeAll()
                } else {
                    collapsedProblemSets = Set(course.problemSets.map(\.persistentModelID))
                }
            } label: {
                Label(
                    allCollapsed ? "Expand all" : "Collapse all",
                    systemImage: allCollapsed
                        ? "rectangle.expand.vertical"
                        : "rectangle.compress.vertical"
                )
            }
            .labelStyle(.titleAndIcon)

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
        .sheet(item: $addingProblemTo) { problemSet in
            AddProblemSheet(problemSet: problemSet)
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

private struct CourseHeatmap: View {
    let problems: [ImageProblem]
    let onSelect: (ImageProblem) -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private let columns = [GridItem(.adaptive(minimum: 10, maximum: 10), spacing: 2, alignment: .leading)]

    var body: some View {
        if problems.isEmpty {
            EmptyView()
        } else {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 2) {
                ForEach(problems) { problem in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color(for: problem.currentDifficulty))
                        .frame(width: 10, height: 10)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(problem)
                        }
                        .help(tooltip(for: problem))
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func color(for difficulty: Difficulty) -> Color {
        switch difficulty {
        case .notAttempted: return Color.gray.opacity(0.4)
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }

    private func tooltip(for problem: ImageProblem) -> String {
        guard let last = problem.lastAttempted else { return "Not attempted" }
        return Self.dateFormatter.string(from: last)
    }
}
