//
//  CreateCourseSheet.swift
//  pgrind
//
//  Created by Zack Adlington on 15/05/2026.
//

import SwiftData
import SwiftUI

struct CreateCourseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Topic.createdDate, order: .forward) private var topics: [Topic]

    @State private var title: String = ""
    @State private var summary: String = ""
    @State private var hyperlink: String = ""
    @State private var selectedTopic: Topic?
    @State private var showingCreateTopic = false
    @State private var newTopicName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField(
                    text: $title,
                    prompt: Text("E.g. 'MIT 18.01 | Single Variable Calculus | Fall 2020'")
                ) {
                    Text("Name")
                }
                TextField(
                    text: $summary,
                    prompt: Text(
                        "E.g. 'Master the calculus of derivatives, integrals, " +
                            "coordinate systems, and infinite series.'"
                    ),
                    axis: .vertical
                ) {
                    Text("Description (optional)")
                }
                .lineLimit(3 ... 5)
                TextField(
                    text: $hyperlink,
                    prompt: Text(
                        "E.g. 'https://ocw.mit.edu/courses/" +
                            "18-01-calculus-i-single-variable-calculus-fall-2020/'"
                    )
                ) {
                    Text("Website URL (optional)")
                }
                Picker("Topic (optional)", selection: $selectedTopic) {
                    Text("None").tag(Topic?.none)
                    ForEach(topics) { topic in
                        Text(topic.name).tag(Topic?.some(topic))
                    }
                }
                Button("New Topic…") {
                    newTopicName = ""
                    showingCreateTopic = true
                }
            }
            .formStyle(.grouped)
            .alert("New Topic", isPresented: $showingCreateTopic) {
                TextField("Name", text: $newTopicName)
                Button("Cancel", role: .cancel) { newTopicName = "" }
                Button("Create") {
                    let trimmed = newTopicName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        let topic = Topic(name: trimmed)
                        modelContext.insert(topic)
                        try? modelContext.save()
                        selectedTopic = topic
                    }
                    newTopicName = ""
                }
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("Create") {
                    let newCourse = Course(
                        title: title,
                        summary: summary,
                        hyperlink: hyperlink
                    )
                    newCourse.topic = selectedTopic
                    modelContext.insert(newCourse)
                    try? modelContext.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 480, minHeight: 320)
        .navigationTitle("Create a new course")
    }
}
