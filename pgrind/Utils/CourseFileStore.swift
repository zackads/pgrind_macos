import AppKit
import Foundation
import SwiftData

@MainActor
enum CourseFileStore {
    private static let subdirectory = "CourseFiles"

    static func directory(for course: Course) throws -> URL {
        let url = StorageLocation.currentFolder
            .appending(path: subdirectory)
            .appending(path: course.ensureFolderID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func url(for file: CourseFile) -> URL {
        let base = StorageLocation.currentFolder
            .appending(path: subdirectory)
            .appending(path: file.course.ensureFolderID().uuidString)
        return base.appending(path: file.filename)
    }

    @discardableResult
    static func importFile(at sourceURL: URL, into course: Course, in context: ModelContext) throws -> CourseFile {
        let didStartAccess = sourceURL.startAccessingSecurityScopedResource()
        defer { if didStartAccess { sourceURL.stopAccessingSecurityScopedResource() } }

        let dir = try directory(for: course)
        let originalName = sourceURL.lastPathComponent
        let destinationName = uniqueFilename(originalName, in: dir)
        let destinationURL = dir.appending(path: destinationName)

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        let file = CourseFile(course: course, filename: destinationName, displayName: originalName)
        context.insert(file)
        course.files.append(file)
        try context.save()
        return file
    }

    static func delete(_ file: CourseFile, in context: ModelContext) throws {
        let fileURL = url(for: file)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        context.delete(file)
        try context.save()
    }

    static func open(_ file: CourseFile) {
        NSWorkspace.shared.open(url(for: file))
    }

    private static func uniqueFilename(_ name: String, in directory: URL) -> String {
        let fileManager = FileManager.default
        let candidate = directory.appending(path: name)
        if !fileManager.fileExists(atPath: candidate.path) { return name }

        let nameAsNS = name as NSString
        let stem = nameAsNS.deletingPathExtension
        let ext = nameAsNS.pathExtension

        var index = 2
        while true {
            let suffixed = ext.isEmpty ? "\(stem) (\(index))" : "\(stem) (\(index)).\(ext)"
            let url = directory.appending(path: suffixed)
            if !fileManager.fileExists(atPath: url.path) {
                return suffixed
            }
            index += 1
        }
    }
}
