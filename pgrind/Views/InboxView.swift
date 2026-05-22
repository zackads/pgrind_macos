//
//  InboxView.swift
//  pgrind
//

import SwiftData
import SwiftUI

struct InboxView: View {
    @Binding var path: [Home.Route]
    let problems: [ImageProblem]

    @Environment(\.modelContext) private var modelContext
    @State private var problemPendingRemoval: ImageProblem?

    var body: some View {
        Group {
            if problems.isEmpty {
                ContentUnavailableView(
                    "No more problems!",
                    systemImage: "tray",
                    description: Text("Come back soon.")
                )
            } else {
                ScrollView {
                    ProblemsGalleryView(
                        problems: problems,
                        onSelect: { problem in
                            path.append(.recordAttempt(problem))
                        },
                        contextMenu: { problem in
                            Button("Remove from Inbox…", role: .destructive) {
                                problemPendingRemoval = problem
                            }
                        }
                    )
                }
            }
        }
        .navigationTitle("Inbox")
        .confirmationDialog(
            "Remove this problem from your Inbox?",
            isPresented: removalDialogBinding,
            presenting: problemPendingRemoval
        ) { problem in
            Button("Remove without attempting", role: .destructive) {
                remove(problem)
            }
            Button("Keep in Inbox", role: .cancel) {
                problemPendingRemoval = nil
            }
        } message: { _ in
            Text(
                "You learn by attempting problems, not skipping them. "
                + "Removing it won't undo this decision — the problem stays "
                + "in its problem set, but you won't see it here again."
            )
        }
    }

    private var removalDialogBinding: Binding<Bool> {
        Binding(
            get: { problemPendingRemoval != nil },
            set: { if !$0 { problemPendingRemoval = nil } }
        )
    }

    private func remove(_ problem: ImageProblem) {
        problem.inInbox = false
        try? modelContext.save()
        problemPendingRemoval = nil
    }
}
