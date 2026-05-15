//
//  CourseView.swift
//  pgrind
//
//  Created by Zack Adlington on 15/05/2026.
//

import SwiftUI
import SwiftData

struct CourseView: View {
    @Binding var path: [Home.Route]
    var course: Course
    
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        List(course.problemSets) { ps in
                                    VStack(alignment: .leading) {
                                        Text(ps.name)
                                            .font(.title3)
                                        ProblemsGalleryView(problems: ps.problems) { problem in
                                            path.append(.viewProblem(problem))
                                        }
                                    }
                                    .tag(ps)
                                }
                                .navigationTitle(course.title)
                                .toolbar {
                                    Button {
                                        openWindow(id: "create-problem", value: course.persistentModelID)
                                    } label: {
                                        Label("New", systemImage: "plus")
                                    }
                                    .keyboardShortcut("n", modifiers: [.command])
                                    .labelStyle(.titleAndIcon)
                                }
    }
}
