import SwiftData
import SwiftUI

struct AddSolutionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let problem: ImageProblem

    @State private var solutionImagesData: [Data] = []

    var body: some View {
        NavigationStack {
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
            .navigationTitle("Add solution")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let merged = Screenshotter.mergeImagesVertically(from: solutionImagesData) {
                            problem.solutionImage = merged
                            do {
                                try modelContext.save()
                                dismiss()
                            } catch {
                                print("Failed to save model context: \(error)")
                            }
                        }
                    }
                    .disabled(solutionImagesData.isEmpty)
                }
            }
        }
    }
}
