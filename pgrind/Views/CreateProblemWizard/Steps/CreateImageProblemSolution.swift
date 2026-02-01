import SwiftUI
import AppKit
import SwiftData

struct CreateImageProblemSolution: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var path: [CreateProblemWizard.Route]
    var imageProblem: ImageProblem
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State var solutionImagesData: [Data] = []
    
    var body: some View {
        ScrollView {
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
        }
        .navigationTitle("Create an image problem")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if !(solutionImagesData == []), let mergedSolution = Screenshotter.mergeImagesVertically(from: solutionImagesData) {
                        imageProblem.solutionImage = mergedSolution
                    }
                    
                    onSave()
                }
            }
        }
        
    }
}
