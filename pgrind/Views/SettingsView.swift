import AppKit
import SwiftUI

struct SettingsView: View {
    @State private var displayPath: String = StorageLocation.displayPath
    @State private var isUsingCustom: Bool = StorageLocation.isUsingCustomLocation
    @State private var pendingFolder: URL?
    @State private var showMigrationAlert = false
    @State private var showRelaunchAlert = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Storage Location") {
                LabeledContent("Current folder") {
                    Text(displayPath)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }

                HStack {
                    Button("Choose Folder…") {
                        pickFolder()
                    }
                    if isUsingCustom {
                        Button("Revert to Default") {
                            pendingFolder = StorageLocation.defaultFolder
                            showMigrationAlert = true
                        }
                    }
                }

                Text(
                    """
                    pgrind stores your library in this folder. To sync between Macs, \
                    pick a folder inside iCloud Drive. **Don't open pgrind on two \
                    Macs at the same time** — the underlying SQLite database isn't \
                    safe under concurrent multi-machine writes and can corrupt.
                    """
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 280)
        .alert("Move existing library?", isPresented: $showMigrationAlert, presenting: pendingFolder) { folder in
            Button("Move") {
                applyChange(folder: folder, copyExisting: true)
            }
            Button("Use Empty Folder") {
                applyChange(folder: folder, copyExisting: false)
            }
            Button("Cancel", role: .cancel) {
                pendingFolder = nil
            }
        } message: { folder in
            Text(
                """
                Copy your current pgrind data into \(folder.lastPathComponent)? \
                Choose “Use Empty Folder” to start fresh at the new location \
                (your current data stays where it is).
                """
            )
        }
        .alert("Relaunch pgrind", isPresented: $showRelaunchAlert) {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text("Quit and reopen pgrind to start using the new storage location.")
        }
        .alert("Couldn't change storage location", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.message = "Pick the folder where pgrind should store your library."
        guard panel.runModal() == .OK, let folder = panel.url else { return }
        pendingFolder = folder
        showMigrationAlert = true
    }

    private func applyChange(folder: URL, copyExisting: Bool) {
        let oldFolder = StorageLocation.currentFolder
        do {
            if folder == StorageLocation.defaultFolder {
                if copyExisting {
                    try StorageLocation.migrateStoreFiles(from: oldFolder, to: folder)
                }
                StorageLocation.clearCustomLocation()
            } else {
                if copyExisting {
                    try StorageLocation.migrateStoreFiles(from: oldFolder, to: folder)
                }
                try StorageLocation.setCustomLocation(folder)
            }
            displayPath = StorageLocation.displayPath
            isUsingCustom = StorageLocation.isUsingCustomLocation
            pendingFolder = nil
            showRelaunchAlert = true
        } catch {
            errorMessage = error.localizedDescription
            pendingFolder = nil
        }
    }
}
