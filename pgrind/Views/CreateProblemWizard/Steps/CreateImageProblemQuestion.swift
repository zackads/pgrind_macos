import SwiftUI
import AppKit
import SwiftData

struct CreateImageProblemQuestion: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var path: [CreateProblemWizard.Route]
    var problemSet: ProblemSet
    let onCancel: () -> Void
    
    @State var questionImagesData: [Data] = []
    
    var body: some View {
        ScrollView {
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
        }
        .navigationTitle("Create an image problem")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Continue") {
                    if let mergedQuestion = Screenshotter.mergeImagesVertically(from: questionImagesData) {
                        let imageProblem = ImageProblem(
                            problemSet: problemSet,
                            questionImage: mergedQuestion
                        )
                        
                        problemSet.problems.append(imageProblem)
                        
                        path.append(.createImageProblemSolution(imageProblem))
                    }
                }
                .disabled(questionImagesData.isEmpty)
            }
        }
        
    }
    
    
}
