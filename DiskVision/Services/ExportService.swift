import Foundation
import AppKit

class ExportService {
    static func exportAsText(rootNode: FileNode, to path: String) -> Bool {
        var text = "DiskVision Export\n"
        text += "================\n"
        text += "Scan Date: \(Date())\n"
        text += "Root: \(rootNode.path)\n"
        text += "Total Size: \(ByteCountFormatter.string(fromByteCount: rootNode.totalSize, countStyle: .file))\n\n"
        text += "Directory Structure:\n"
        text += "-------------------\n"

        writeNodeTree(rootNode, to: &text, indent: 0)

        do {
            try text.write(toFile: path, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    private static func writeNodeTree(_ node: FileNode, to text: inout String, indent: Int) {
        let prefix = String(repeating: "  ", count: indent)
        let sizeStr = ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file)
        text += "\(prefix)\(node.name) [\(sizeStr)]\n"

        if node.isDirectory {
            for child in node.sortedChildren(by: .sizeDesc) {
                writeNodeTree(child, to: &text, indent: indent + 1)
            }
        }
    }

    static func exportAsImage(
        nodes: [FileNode],
        size: CGSize,
        colorMapper: FileColorMapper,
        colorContext: ColorContext,
        to path: String
    ) -> Bool {
        guard let image = TreemapRenderer.exportImage(
            nodes: nodes,
            size: size,
            colorMapper: colorMapper,
            colorContext: colorContext
        ) else { return false }

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return false
        }

        do {
            try pngData.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            return false
        }
    }

    static func showSavePanel(
        title: String,
        allowedFileTypes: [String],
        defaultName: String
    ) -> URL? {
        let panel = NSSavePanel()
        panel.title = title
        panel.allowedFileTypes = allowedFileTypes
        panel.nameFieldStringValue = defaultName
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    static func showOpenPanel(
        title: String,
        allowsMultipleSelection: Bool = false
    ) -> [URL]? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = allowsMultipleSelection
        panel.prompt = "Select"

        guard panel.runModal() == .OK else { return nil }
        return panel.urls
    }
}
