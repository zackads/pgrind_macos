//
//  InboxView.swift
//  pgrind
//

import SwiftUI

struct InboxView: View {
    @Binding var path: [Home.Route]
    let problems: [ImageProblem]

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
                    ProblemsGalleryView(problems: problems) { problem in
                        path.append(.recordAttempt(problem))
                    }
                }
            }
        }
        .navigationTitle("Inbox")
    }
}
