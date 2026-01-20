import SwiftUI
import AppKit
import SwiftData

struct CreateImageProblem: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var path: [Route]
    var problemSet: ProblemSet
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State var questionImagesData: [Data] = []
    @State var solutionImagesData: [Data] = []
    
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
                                        if let newData = await takeScreenshot() {
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
                                if let newData = await takeScreenshot() {
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
                                        if let newData = await takeScreenshot() {
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
                                if let newData = await takeScreenshot() {
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
                    if let mergedQuestion = mergeImagesVertically(from: questionImagesData), let mergedSolution = mergeImagesVertically(from: solutionImagesData) {
                        
                        modelContext.insert(
                            ImageProblem(
                                problemSet: problemSet,
                                questionImage: mergedQuestion,
                                solutionImage: mergedSolution)
                        )
                        
                        onSave()
                    }
                    
                }
                .disabled(questionImagesData.isEmpty)
            }
        }
        
    }
    
    @MainActor
    private func takeScreenshot() async -> Data? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")

        // Minimize the current window if possible; otherwise hide the app.
        let window = NSApp.keyWindow ?? NSApp.mainWindow
        var didMiniaturize = false
        if let window, !window.isMiniaturized {
            window.miniaturize(nil)
            didMiniaturize = true
        } else {
            NSApp.hide(nil)
        }

        // Run screencapture asynchronously and wait for completion.
        let capturedData: Data? = await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = [
                "-i", // interactive selection, similar to Cmd + Shift + 4
                tempURL.path
            ]
            process.terminationHandler = { _ in
                let result: Data?
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    result = try? Data(contentsOf: tempURL)
                    try? FileManager.default.removeItem(at: tempURL)
                } else {
                    result = nil
                }
                continuation.resume(returning: result)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(returning: nil)
            }
        }

        // Restore the window/app to its previous state.
        if didMiniaturize, let window {
            window.deminiaturize(nil)
            window.makeKeyAndOrderFront(nil)
        } else {
            NSApp.unhide(nil)
            NSApp.activate(ignoringOtherApps: true)
        }

        return capturedData
    }
    
    private func mergeImagesVertically(from imagesData: [Data]) -> Data? {
        let nsImages: [NSImage] = imagesData.compactMap { NSImage(data: $0) }
        guard !nsImages.isEmpty else { return nil }

        // Compute total height and max width
        var totalHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        var reps: [(NSBitmapImageRep, CGSize)] = []

        for img in nsImages {
            guard let rep = bestBitmapRep(for: img) else { continue }
            reps.append((rep, rep.size))
            totalHeight += rep.size.height
            maxWidth = max(maxWidth, rep.size.width)
        }

        guard !reps.isEmpty else { return nil }

        let finalSize = NSSize(width: maxWidth, height: totalHeight)
        guard let finalRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(finalSize.width),
            pixelsHigh: Int(finalSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: finalRep)

        NSColor.clear.set()
        NSRect(origin: .zero, size: finalSize).fill()

        var y: CGFloat = finalSize.height
        for (rep, size) in reps {
            y -= size.height
            let rect = NSRect(x: 0, y: y, width: size.width, height: size.height)
            rep.draw(in: rect)
        }

        NSGraphicsContext.restoreGraphicsState()

        let finalImage = NSImage(size: finalSize)
        finalImage.addRepresentation(finalRep)

        return finalImage.tiffRepresentation
    }

    private func bestBitmapRep(for image: NSImage) -> NSBitmapImageRep? {
        if let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first {
            return rep
        }
        guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep
    }
}

private struct PiledImagesView: View {
    let imagesData: [Data]

    var body: some View {
        ZStack {
            ForEach(Array(imagesData.enumerated()), id: \.offset) { index, data in
                if let img = NSImage(data: data) {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                        .rotationEffect(.degrees(Double(index % 5 - 2) * 2))
                        .offset(x: CGFloat(index % 3 - 1) * 8, y: CGFloat(index % 3 - 1) * -8)
                        .shadow(radius: 3, y: 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .padding(6)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
