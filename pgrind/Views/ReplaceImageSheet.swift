import SwiftData
import SwiftUI

struct ReplaceImageSheet: View {
    enum Kind: String, Identifiable {
        case question
        case solution

        var id: String { rawValue }

        var title: String {
            switch self {
            case .question: "Replace question"
            case .solution: "Replace solution"
            }
        }

        var sectionTitle: String {
            switch self {
            case .question: "Question image"
            case .solution: "Solution image"
            }
        }

        var instruction: String {
            switch self {
            case .question: "Take a screenshot of the new question."
            case .solution: "Take a screenshot of the new solution."
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let problem: ImageProblem
    let kind: Kind

    @State private var imagesData: [Data] = []

    var body: some View {
        NavigationStack {
            Form {
                Section(kind.sectionTitle) {
                    Text(kind.instruction)
                        .font(.headline)
                    Text("The existing image will be replaced when you save.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !imagesData.isEmpty {
                        VStack(spacing: 12) {
                            PiledImagesView(imagesData: imagesData)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            HStack {
                                Button {
                                    Task { @MainActor in
                                        if let newData = await Screenshotter.takeScreenshot() {
                                            imagesData.append(newData)
                                        }
                                    }
                                } label: {
                                    Label("Add another screenshot", systemImage: "plus")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)

                                Button(role: .destructive) {
                                    imagesData.removeAll()
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
                                    imagesData.append(newData)
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
            .navigationTitle(kind.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let merged = Screenshotter.mergeImagesVertically(from: imagesData) else {
                            return
                        }
                        switch kind {
                        case .question:
                            problem.questionImage = merged
                        case .solution:
                            problem.solutionImage = merged
                        }
                        do {
                            try modelContext.save()
                            dismiss()
                        } catch {
                            print("Failed to save model context: \(error)")
                        }
                    }
                    .disabled(imagesData.isEmpty)
                }
            }
        }
    }
}
