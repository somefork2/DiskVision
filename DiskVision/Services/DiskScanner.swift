import Foundation

final class DiskScanner {
    var onProgress: ((Int) -> Void)?
    var onComplete: ((FileNode, ScanResult) -> Void)?

    private(set) var rootNode: FileNode?
    private var scanning = false
    private var cancelled = false
    private var fileCount = 0
    private var folderCount = 0
    private var startTime = Date()
    private var lastEmit = Date.distantPast

    func scan(url: URL) {
        guard !scanning else { return }
        scanning = true
        cancelled = false
        fileCount = 0
        folderCount = 0
        startTime = Date()
        lastEmit = Date.distantPast

        let root = FileNode(name: url.lastPathComponent, path: url.path, isDirectory: true)
        self.rootNode = root

        let _ = url.startAccessingSecurityScopedResource()

        DispatchQueue.global(qos: .userInitiated).async {
            self.scanDir(url: url, parent: root)

            let duration = Date().timeIntervalSince(self.startTime)
            let result = ScanResult(
                rootPath: url.path,
                totalSize: root.totalSize,
                fileCount: self.fileCount,
                folderCount: self.folderCount,
                duration: duration
            )

            DispatchQueue.main.async {
                self.scanning = false
                url.stopAccessingSecurityScopedResource()
                self.onComplete?(root, result)
            }
        }
    }

    func cancel() {
        cancelled = true
    }

    private func scanDir(url: URL, parent: FileNode) {
        guard !cancelled else { return }

        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey, .creationDateKey, .typeIdentifierKey],
            options: []
        ) else { return }

        var dirs: [URL] = []

        for item in items {
            guard !cancelled else { return }

            let rv = try? item.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey, .creationDateKey, .typeIdentifierKey])
            let isDir = rv?.isDirectory ?? false

            let node = FileNode(
                name: item.lastPathComponent,
                path: item.path,
                isDirectory: isDir,
                size: isDir ? 0 : Int64(rv?.fileSize ?? 0),
                modificationDate: rv?.contentModificationDate ?? Date(),
                creationDate: rv?.creationDate ?? Date(),
                fileExtension: item.pathExtension,
                fileType: rv?.typeIdentifier ?? ""
            )
            parent.addChild(node)

            if isDir {
                folderCount += 1
                dirs.append(item)
            } else {
                fileCount += 1
            }
        }

        let now = Date()
        if now.timeIntervalSince(lastEmit) >= 0.3 {
            lastEmit = now
            let total = fileCount + folderCount
            DispatchQueue.main.async {
                self.onProgress?(total)
            }
        }

        for dir in dirs {
            guard !cancelled else { return }
            let child = parent.children.first { $0.path == dir.path }!
            scanDir(url: dir, parent: child)
        }
    }
}
