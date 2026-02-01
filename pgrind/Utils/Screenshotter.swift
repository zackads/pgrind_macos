//
//  Screenshotter.swift
//  pgrind
//
//  Created by Zack Adlington on 01/02/2026.
//

import Foundation
import AppKit

class Screenshotter {
    @MainActor
    static func takeScreenshot() async -> Data? {
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
    
    static func mergeImagesVertically(from imagesData: [Data]) -> Data? {
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

    private static func bestBitmapRep(for image: NSImage) -> NSBitmapImageRep? {
        if let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first {
            return rep
        }
        guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep
    }

}
