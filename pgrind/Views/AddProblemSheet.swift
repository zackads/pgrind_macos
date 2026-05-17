import SwiftData
import SwiftUI

struct AddProblemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let problemSet: ProblemSet

    @State private var questionImagesData: [Data] = []
    @State private var solutionImagesData: [Data] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Question image") {
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

                Section("Solution image (optional)") {
                    Text("Take a screenshot of the solution.")
                        .font(.headline)
                    Text("You can skip this and add a solution later from the problem view.")
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
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .padding(.top, 12)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add problem")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let mergedQuestion = Screenshotter.mergeImagesVertically(from: questionImagesData) else {
                            return
                        }
                        let mergedSolution = solutionImagesData.isEmpty
                            ? nil
                            : Screenshotter.mergeImagesVertically(from: solutionImagesData)

                        let problem = ImageProblem(
                            problemSet: problemSet,
                            questionImage: mergedQuestion,
                            solutionImage: mergedSolution
                        )
                        problemSet.problems.append(problem)

                        do {
                            try modelContext.save()
                            dismiss()
                        } catch {
                            print("Failed to save new problem: \(error)")
                        }
                    }
                    .disabled(questionImagesData.isEmpty)
                }
            }
        }
    }
}
