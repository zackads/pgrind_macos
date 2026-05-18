import Foundation

@MainActor
enum StorageLocation {
    private static let bookmarkKey = "storageBookmark"
    private static let storeFilename = "default.store"
    private static let storeSidecars = ["default.store-wal", "default.store-shm"]
    private static let storeSupport = ".default_SUPPORT"

    private static var resolvedCustomFolder: URL?

    static var defaultFolder: URL {
        URL.applicationSupportDirectory
    }

    static var currentFolder: URL {
        if let folder = resolveCustomFolder() {
            return folder
        }
        return defaultFolder
    }

    static var currentStoreURL: URL {
        currentFolder.appending(path: storeFilename)
    }

    static var displayPath: String {
        currentFolder.path(percentEncoded: false)
    }

    static var isUsingCustomLocation: Bool {
        UserDefaults.standard.data(forKey: bookmarkKey) != nil
    }

    static func setCustomLocation(_ folder: URL) throws {
        let bookmark = try folder.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
        resolvedCustomFolder = nil
    }

    static func clearCustomLocation() {
        if let folder = resolvedCustomFolder {
            folder.stopAccessingSecurityScopedResource()
        }
        resolvedCustomFolder = nil
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }

    /// Copy the store and its sidecars from `source` to `destination`.
    /// Both URLs are folder URLs (not store-file URLs).
    static func migrateStoreFiles(from source: URL, to destination: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

        let names = [storeFilename] + storeSidecars + [storeSupport]
        for name in names {
            let src = source.appending(path: name)
            let dst = destination.appending(path: name)
            guard fileManager.fileExists(atPath: src.path) else { continue }
            if fileManager.fileExists(atPath: dst.path) {
                try fileManager.removeItem(at: dst)
            }
            try fileManager.copyItem(at: src, to: dst)
        }
    }

    @discardableResult
    private static func resolveCustomFolder() -> URL? {
        if let cached = resolvedCustomFolder {
            return cached
        }
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }
        if !url.startAccessingSecurityScopedResource() {
            return nil
        }
        if isStale {
            if let refreshed = try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) {
                UserDefaults.standard.set(refreshed, forKey: bookmarkKey)
            }
        }
        resolvedCustomFolder = url
        return url
    }
}
