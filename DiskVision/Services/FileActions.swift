import Foundation
import AppKit

class FileActions {
    static func revealInFinder(path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }

    static func openFile(path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
    }

    static func quickLook(path: String) {
        let url = URL(fileURLWithPath: path)
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([url], withApplicationAt: URL(fileURLWithPath: "/System/Library/CoreServices/Quick Look UI.app"), configuration: config)
    }

    static func copyPath(_ path: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(path, forType: .string)
    }

    static func moveToTrash(path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            return true
        } catch {
            return false
        }
    }

    static func deleteFile(path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            return false
        }
    }

    static func getFileInfo(path: String) -> FileInformation? {
        let url = URL(fileURLWithPath: path)
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path) else {
            return nil
        }

        let size = attributes[.size] as? Int64 ?? 0
        let modDate = attributes[.modificationDate] as? Date ?? Date()
        let createDate = attributes[.creationDate] as? Date ?? Date()
        let isDir = attributes[.type] as? FileAttributeType == .typeDirectory

        let resourceValues = try? url.resourceValues(forKeys: [.isPackageKey, .isHiddenKey, .typeIdentifierKey])

        return FileInformation(
            name: url.lastPathComponent,
            path: path,
            size: size,
            modificationDate: modDate,
            creationDate: createDate,
            isDirectory: isDir,
            isPackage: resourceValues?.isPackage ?? false,
            isHidden: resourceValues?.isHidden ?? false,
            fileType: resourceValues?.typeIdentifier ?? ""
        )
    }
}

struct FileInformation {
    let name: String
    let path: String
    let size: Int64
    let modificationDate: Date
    let creationDate: Date
    let isDirectory: Bool
    let isPackage: Bool
    let isHidden: Bool
    let fileType: String

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
