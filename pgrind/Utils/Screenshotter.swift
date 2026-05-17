//
//  Screenshotter.swift
//  pgrind
//
//  Created by Zack Adlington on 01/02/2026.
//

import AppKit
import Foundation

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
        let reps: [NSBitmapImageRep] = imagesData.compactMap { NSBitmapImageRep(data: $0) }
        guard !reps.isEmpty else { return nil }

        // Work in pixel space so Retina captures don't get downsampled.
        let maxPixelWidth = reps.map(\.pixelsWide).max() ?? 0
        let totalPixelHeight = reps.map(\.pixelsHigh).reduce(0, +)
        guard maxPixelWidth > 0, totalPixelHeight > 0 else { return nil }

        guard let finalRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: maxPixelWidth,
            pixelsHigh: totalPixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        // Keep the rep's logical size in pixels so drawing maps 1:1.
        finalRep.size = NSSize(width: maxPixelWidth, height: totalPixelHeight)

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        guard let ctx = NSGraphicsContext(bitmapImageRep: finalRep) else { return nil }
        NSGraphicsContext.current = ctx
        ctx.imageInterpolation = .high

        NSColor.white.set()
        NSRect(x: 0, y: 0, width: maxPixelWidth, height: totalPixelHeight).fill()

        var posY = totalPixelHeight
        for rep in reps {
            posY -= rep.pixelsHigh
            let posX = (maxPixelWidth - rep.pixelsWide) / 2
            let rect = NSRect(x: posX, y: posY, width: rep.pixelsWide, height: rep.pixelsHigh)
            // Force a 1:1 pixel draw by temporarily matching the rep's logical size to its pixel dims.
            let originalSize = rep.size
            rep.size = NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
            rep.draw(in: rect)
            rep.size = originalSize
        }

        return finalRep.representation(using: .png, properties: [:])
    }
}
