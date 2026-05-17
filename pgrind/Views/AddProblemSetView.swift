//
//  AddProblemSetView.swift
//  pgrind
//
//  Created by Zack Adlington on 15/05/2026.
//

import SwiftData
import SwiftUI

struct AddProblemSetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let course: Course

    enum Route: Hashable {
        case addProblemQuestion(ProblemSet)
        case addProblemSolution(ProblemSet, ImageProblem)
    }

    @State private var path: [Route] = []

    @State private var name: String = ""
    @State private var problemSet: ProblemSet?
    @State private var problems: [ImageProblem] = []

    @State var questionImagesData: [Data] = []
    @State var solutionImagesData: [Data] = []

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                TextField(text: $name, prompt: Text("E.g. 'Week 7'")) {
                    Text("Name")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add problem set to \(course.title)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add new problem") {
                        let newSet = ProblemSet(
                            course: course,
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        modelContext.insert(newSet)
                        problemSet = newSet
                        path.append(.addProblemQuestion(newSet))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case let .addProblemQuestion(ps):
                    Form {
                        Section("Problem image") {
                            Text("Take a screenshot of the problem.")
                                .font(.headline)
                            Text("For example, you can screenshot a past exam paper question from a .pdf file.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if !questionImagesData.isEmpty {
                                VStack(spacing: 12) {
                                    PiledImagesView(imagesData: questionImagesData)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    HStack {
                                        Button {
                                            Task { @MainActor in
                                                if let newData = await Screenshotter.takeScreenshot() {
                                                    questionImagesData.append(newData)
                                                }
                                            }
                                        } label: {
                                            Label("Add another screenshot", systemImage: "plus")
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.large)

                                        Button(role: .destructive) {
                                            questionImagesData.removeAll()
                                        } label: {
                                            Label("Clear", systemImage: "trash")
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.large)
                                    }
                                }
                                .padding(.top, 12)
                            } else {
                                Button {
                                    Task { @MainActor in
                                        if let newData = await Screenshotter.takeScreenshot() {
                                            questionImagesData.append(newData)
                                        }
                                    }
                                } label: {
                                    Label("Take a screenshot", systemImage: "camera.viewfinder")
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.extraLarge)
                                .padding(.top, 24)
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .formStyle(.grouped)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Continue") {
                                if let mergedQuestion = Screenshotter.mergeImagesVertically(from: questionImagesData) {
                                    let ip = ImageProblem(
                                        problemSet: ps,
                                        questionImage: mergedQuestion
                                    )

                                    ps.problems.append(ip)

                                    do {
                                        try modelContext.save()
                                        questionImagesData = []
                                        path.append(.addProblemSolution(ps, ip))
                                    } catch {
                                        print("Failed to save model context: \(error)")
                                    }
                                }
                            }
                            .disabled(questionImagesData.isEmpty)
                        }
                    }
                case let .addProblemSolution(ps, ip):
                    Form {
                        Section("Solution image") {
                            Text("Take a screenshot of the solution.")
                                .font(.headline)
                            Text("For example, a worked solution from a .pdf of a past exam paper or problem sheet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if !solutionImagesData.isEmpty {
                                VStack(spacing: 12) {
                                    PiledImagesView(imagesData: solutionImagesData)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    HStack {
                                        Button {
                                            Task { @MainActor in
                                                if let newData = await Screenshotter.takeScreenshot() {
                                                    solutionImagesData.append(newData)
                                                }
                                            }
                                        } label: {
                                            Label("Add another screenshot", systemImage: "plus")
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.large)

                                        Button(role: .destructive) {
                                            solutionImagesData.removeAll()
                                        } label: {
                                            Label("Clear", systemImage: "trash")
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.large)
                                    }
                                }
                                .padding(.top, 12)
                            } else {
                                Button {
                                    Task { @MainActor in
                                        if let newData = await Screenshotter.takeScreenshot() {
                                            solutionImagesData.append(newData)
                                        }
                                    }
                                } label: {
                                    Label("Take a screenshot", systemImage: "camera.viewfinder")
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.extraLarge)
                                .padding(.top, 24)
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .formStyle(.grouped)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save and add more problems") {
                                if !(solutionImagesData == []), let mergedSolution = Screenshotter.mergeImagesVertically(from: solutionImagesData) {
                                    ip.solutionImage = mergedSolution
                                }

                                do {
                                    try modelContext.save()
                                    solutionImagesData = []
                                    path.append(.addProblemQuestion(ps))
                                } catch {
                                    print("Failed to save model context: \(error)")
                                }
                            }
                        }

                        ToolbarItem(placement: .automatic) {
                            Button("Save and finish") {
                                if !(solutionImagesData == []), let mergedSolution = Screenshotter.mergeImagesVertically(from: solutionImagesData) {
                                    ip.solutionImage = mergedSolution
                                }

                                do {
                                    try modelContext.save()
                                    dismiss()
                                } catch {
                                    print("Failed to save model context: \(error)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
