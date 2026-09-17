import Foundation

struct ScanResult: Codable, Identifiable {
    let id: UUID
    let scanDate: Date
    let rootPath: String
    let totalSize: Int64
    let fileCount: Int
    let folderCount: Int
    let duration: TimeInterval

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var formattedDuration: String {
        String(format: "%.1fs", duration)
    }

    init(
        rootPath: String,
        totalSize: Int64,
        fileCount: Int,
        folderCount: Int,
        duration: TimeInterval
    ) {
        self.id = UUID()
        self.scanDate = Date()
        self.rootPath = rootPath
        self.totalSize = totalSize
        self.fileCount = fileCount
        self.folderCount = folderCount
        self.duration = duration
    }
}
