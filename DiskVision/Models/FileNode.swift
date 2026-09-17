import Foundation
import SwiftUI

final class FileNode: Identifiable, Hashable, ObservableObject {
    static func == (lhs: FileNode, rhs: FileNode) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date
    let creationDate: Date
    let lastAccessDate: Date
    let fileExtension: String
    let fileType: String
    let isPackage: Bool
    let isHidden: Bool

    @Published var children: [FileNode] = []
    @Published var isVisible: Bool = true
    @Published var isFiltered: Bool = false

    var parent: FileNode?
    var calculatedSize: Int64 = 0
    var layoutRect: CGRect = .zero
    var depth: Int = 0

    var totalSize: Int64 {
        if children.isEmpty {
            return size
        }
        return children.reduce(0) { $0 + $1.totalSize }
    }

    var percentage: Double = 0.0
    var color: Color = .gray

    init(
        name: String,
        path: String,
        isDirectory: Bool,
        size: Int64 = 0,
        modificationDate: Date = Date(),
        creationDate: Date = Date(),
        lastAccessDate: Date = Date(),
        fileExtension: String = "",
        fileType: String = "",
        isPackage: Bool = false,
        isHidden: Bool = false
    ) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.size = size
        self.modificationDate = modificationDate
        self.creationDate = creationDate
        self.lastAccessDate = lastAccessDate
        self.fileExtension = fileExtension
        self.fileType = fileType
        self.isPackage = isPackage
        self.isHidden = isHidden
    }

    func addChild(_ child: FileNode) {
        child.parent = self
        child.depth = depth + 1
        children.append(child)
    }

    func sortedChildren(by sort: SortOption) -> [FileNode] {
        switch sort {
        case .sizeDesc:
            return children.sorted { $0.totalSize > $1.totalSize }
        case .sizeAsc:
            return children.sorted { $0.totalSize < $1.totalSize }
        case .nameAsc:
            return children.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDesc:
            return children.sorted { $0.name.lowercased() > $1.name.lowercased() }
        case .dateDesc:
            return children.sorted { $0.modificationDate > $1.modificationDate }
        case .dateAsc:
            return children.sorted { $0.modificationDate < $1.modificationDate }
        }
    }
}

enum SortOption: String, CaseIterable {
    case sizeDesc = "Size (Largest)"
    case sizeAsc = "Size (Smallest)"
    case nameAsc = "Name (A-Z)"
    case nameDesc = "Name (Z-A)"
    case dateDesc = "Date (Newest)"
    case dateAsc = "Date (Oldest)"
}
