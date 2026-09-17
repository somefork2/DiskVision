import Foundation
import AppKit

class DiskScanner {
    var onProgress: ((Double, Int) -> Void)?
    var onComplete: ((FileNode, ScanResult) -> Void)?

    private(set) var rootNode: FileNode?
    private var isScanning = false
    private var shouldCancel = false
    private var fileCount = 0
    private var folderCount = 0
    private var startTime: Date?
    private var lastEmitTime: Date = .distantPast
    private var scanTask: Task<Void, Never>?
    private var accessedURLs: [URL] = []

    func scan(url: URL) {
        guard !isScanning else { return }

        let accessing = url.startAccessingSecurityScopedResource()
        if accessing { accessedURLs.append(url) }

        isScanning = true
        shouldCancel = false
        fileCount = 0
        folderCount = 0
        startTime = Date()
        lastEmitTime = .distantPast

        let root = FileNode(name: url.lastPathComponent, path: url.path, isDirectory: true)
        rootNode = root

        scanTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            await self.scanAsync(root)
            let duration = Date().timeIntervalSince(self.startTime ?? Date())
            let result = ScanResult(rootPath: url.path, totalSize: root.totalSize, fileCount: self.fileCount, folderCount: self.folderCount, duration: duration)
            await MainActor.run {
                self.isScanning = false
                self.onComplete?(root, result)
                self.accessedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
                self.accessedURLs.removeAll()
            }
        }
    }

    func cancel() {
        shouldCancel = true
        scanTask?.cancel()
        accessedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        accessedURLs.removeAll()
    }

    private func scanAsync(_ parent: FileNode) async {
        guard !shouldCancel, !Task.isCancelled else { return }

        let fm = FileManager.default
        let url = URL(fileURLWithPath: parent.path)

        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isHiddenKey, .isPackageKey, .contentModificationDateKey, .creationDateKey, .typeIdentifierKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        var subdirs: [FileNode] = []

        for item in contents {
            guard !shouldCancel, !Task.isCancelled else { return }
            let rv = try? item.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .isHiddenKey, .isPackageKey, .contentModificationDateKey, .creationDateKey, .typeIdentifierKey])
            let isDir = rv?.isDirectory ?? false
            let node = FileNode(
                name: item.lastPathComponent,
                path: item.path,
                isDirectory: isDir,
                size: isDir ? 0 : Int64(rv?.fileSize ?? 0),
                modificationDate: rv?.contentModificationDate ?? Date(),
                creationDate: rv?.creationDate ?? Date(),
                fileExtension: item.pathExtension,
                fileType: rv?.typeIdentifier ?? "",
                isPackage: rv?.isPackage ?? false,
                isHidden: rv?.isHidden ?? false
            )
            parent.addChild(node)
            if isDir { folderCount += 1; subdirs.append(node) }
            else { fileCount += 1 }
        }

        await emitProgressIfNeeded()

        for child in subdirs {
            guard !shouldCancel, !Task.isCancelled else { return }
            await scanAsync(child)
        }
    }

    private func emitProgressIfNeeded() async {
        let now = Date()
        guard now.timeIntervalSince(lastEmitTime) >= 0.3 else { return }
        lastEmitTime = now
        let total = fileCount + folderCount
        await MainActor.run {
            self.onProgress?(min(Double(total) / 2000.0, 0.99), total)
        }
    }
}
