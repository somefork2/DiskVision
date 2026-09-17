import SwiftUI

enum ColorMapping: String, CaseIterable, Identifiable {
    case fileSize = "File Size"
    case fileExtension = "Extension"
    case fileType = "Type"
    case parentFolder = "Parent Folder"
    case topLevelFolder = "Top Folder"
    case depth = "Depth"
    case modificationDate = "Modified"
    case creationDate = "Created"
    case lastAccessDate = "Accessed"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fileSize: return "ruler"
        case .fileExtension: return "doc.text"
        case .fileType: return "folder"
        case .parentFolder: return "folder.fill"
        case .topLevelFolder: return "externaldrive"
        case .depth: return "layershift"
        case .modificationDate: return "calendar"
        case .creationDate: return "calendar.badge.plus"
        case .lastAccessDate: return "clock"
        }
    }
}

enum ColorPalette: String, CaseIterable, Identifiable {
    case vivid = "Vivid"
    case pastel = "Pastel"
    case ocean = "Ocean"
    case sunset = "Sunset"
    case forest = "Forest"
    case monochrome = "Monochrome"
    case neon = "Neon"
    case candy = "Candy"

    var id: String { rawValue }

    var colors: [Color] {
        switch self {
        case .vivid: // GrandPerspective-inspired warm palette
            return [
                Color(red: 0.85, green: 0.35, blue: 0.25), // Warm red
                Color(red: 0.95, green: 0.55, blue: 0.15), // Orange
                Color(red: 0.95, green: 0.75, blue: 0.20), // Yellow
                Color(red: 0.40, green: 0.75, blue: 0.35), // Green
                Color(red: 0.25, green: 0.65, blue: 0.75), // Teal
                Color(red: 0.30, green: 0.50, blue: 0.80), // Blue
                Color(red: 0.55, green: 0.35, blue: 0.70), // Purple
                Color(red: 0.80, green: 0.40, blue: 0.55), // Pink
                Color(red: 0.60, green: 0.45, blue: 0.30), // Brown
                Color(red: 0.50, green: 0.70, blue: 0.45), // Sage
            ]
        case .pastel:
            return [
                Color(red: 0.98, green: 0.73, blue: 0.73),
                Color(red: 0.98, green: 0.85, blue: 0.73),
                Color(red: 0.98, green: 0.98, blue: 0.73),
                Color(red: 0.73, green: 0.98, blue: 0.73),
                Color(red: 0.73, green: 0.92, blue: 0.98),
                Color(red: 0.73, green: 0.73, blue: 0.98),
                Color(red: 0.92, green: 0.73, blue: 0.98),
                Color(red: 0.98, green: 0.73, blue: 0.92),
            ]
        case .ocean:
            return [
                Color(red: 0.0, green: 0.32, blue: 0.53),
                Color(red: 0.0, green: 0.45, blue: 0.67),
                Color(red: 0.0, green: 0.59, blue: 0.80),
                Color(red: 0.0, green: 0.72, blue: 0.93),
                Color(red: 0.13, green: 0.85, blue: 1.0),
                Color(red: 0.33, green: 0.92, blue: 1.0),
            ]
        case .sunset:
            return [
                Color(red: 0.93, green: 0.16, blue: 0.22),
                Color(red: 0.96, green: 0.36, blue: 0.13),
                Color(red: 1.0, green: 0.60, blue: 0.0),
                Color(red: 1.0, green: 0.80, blue: 0.0),
                Color(red: 0.83, green: 0.33, blue: 0.67),
                Color(red: 0.60, green: 0.20, blue: 0.60),
            ]
        case .forest:
            return [
                Color(red: 0.0, green: 0.27, blue: 0.13),
                Color(red: 0.13, green: 0.42, blue: 0.20),
                Color(red: 0.27, green: 0.57, blue: 0.27),
                Color(red: 0.40, green: 0.72, blue: 0.33),
                Color(red: 0.53, green: 0.87, blue: 0.40),
                Color(red: 0.73, green: 0.93, blue: 0.53),
            ]
        case .monochrome:
            return (0..<12).map { i in
                Color(white: Double(i) / 11.0)
            }
        case .neon:
            return [
                Color(red: 1.0, green: 0.0, blue: 0.5),
                Color(red: 1.0, green: 0.0, blue: 1.0),
                Color(red: 0.5, green: 0.0, blue: 1.0),
                Color(red: 0.0, green: 0.5, blue: 1.0),
                Color(red: 0.0, green: 1.0, blue: 1.0),
                Color(red: 0.0, green: 1.0, blue: 0.5),
                Color(red: 0.5, green: 1.0, blue: 0.0),
                Color(red: 1.0, green: 1.0, blue: 0.0),
                Color(red: 1.0, green: 0.5, blue: 0.0),
            ]
        case .candy:
            return [
                Color(red: 1.0, green: 0.4, blue: 0.6),
                Color(red: 1.0, green: 0.6, blue: 0.4),
                Color(red: 1.0, green: 0.8, blue: 0.4),
                Color(red: 0.6, green: 1.0, blue: 0.6),
                Color(red: 0.4, green: 0.8, blue: 1.0),
                Color(red: 0.6, green: 0.6, blue: 1.0),
                Color(red: 0.8, green: 0.6, blue: 1.0),
                Color(red: 1.0, green: 0.6, blue: 1.0),
            ]
        }
    }
}

struct FileColorMapper {
    let mapping: ColorMapping
    let palette: ColorPalette

    func color(for node: FileNode, context: ColorContext) -> Color {
        let colors = palette.colors

        switch mapping {
        case .fileSize:
            let ratio = Double(node.totalSize) / Double(max(context.maxSize, 1))
            let index = min(Int(ratio * Double(colors.count)), colors.count - 1)
            return colors[max(0, index)]

        case .fileExtension:
            let hash = abs(node.fileExtension.hashValue)
            return colors[hash % colors.count]

        case .fileType:
            let hash = abs(node.fileType.hashValue)
            return colors[hash % colors.count]

        case .parentFolder:
            let parentName = node.parent?.name ?? "root"
            let hash = abs(parentName.hashValue)
            return colors[hash % colors.count]

        case .topLevelFolder:
            let topFolder = findTopFolder(node)
            let hash = abs(topFolder.hashValue)
            return colors[hash % colors.count]

        case .depth:
            let maxDepth = context.maxDepth
            guard maxDepth > 0 else { return colors[0] }
            let ratio = Double(node.depth) / Double(maxDepth)
            let index = min(Int(ratio * Double(colors.count)), colors.count - 1)
            return colors[max(0, index)]

        case .modificationDate:
            let ratio = dateRatio(node.modificationDate, min: context.earliestDate, max: context.latestDate)
            let index = min(Int(ratio * Double(colors.count)), colors.count - 1)
            return colors[max(0, index)]

        case .creationDate:
            let ratio = dateRatio(node.creationDate, min: context.earliestDate, max: context.latestDate)
            let index = min(Int(ratio * Double(colors.count)), colors.count - 1)
            return colors[max(0, index)]

        case .lastAccessDate:
            let ratio = dateRatio(node.lastAccessDate, min: context.earliestDate, max: context.latestDate)
            let index = min(Int(ratio * Double(colors.count)), colors.count - 1)
            return colors[max(0, index)]
        }
    }

    private func findTopFolder(_ node: FileNode) -> String {
        var current: FileNode? = node
        while let parent = current?.parent {
            if parent.parent == nil { return parent.name }
            current = parent
        }
        return node.name
    }

    private func dateRatio(_ date: Date, min minDate: Date, max maxDate: Date) -> Double {
        let range = maxDate.timeIntervalSince(minDate)
        guard range > 0 else { return 0.5 }
        return (date.timeIntervalSince(minDate) / range).clamped(to: 0...1)
    }
}

struct ColorContext {
    let maxSize: Int64
    let maxDepth: Int
    let earliestDate: Date
    let latestDate: Date
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
