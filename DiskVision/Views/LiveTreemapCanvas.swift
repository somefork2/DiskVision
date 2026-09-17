import SwiftUI

struct LiveTreemapCanvas: View {
    let root: FileNode
    let size: CGSize
    let version: Int

    var body: some View {
        Canvas { context, canvasSize in
            let bg = Color(red: 0.06, green: 0.06, blue: 0.12)
            context.fill(Path(CGRect(origin: .zero, size: canvasSize)), with: .color(bg))

            let children = root.children.filter { $0.totalSize > 0 }
            guard !children.isEmpty else { return }

            let totalSize = children.reduce(Int64(0)) { $0 + $1.totalSize }
            guard totalSize > 0 else { return }

            let sorted = children.sorted { $0.totalSize > $1.totalSize }
            let rect = CGRect(origin: .zero, size: canvasSize).insetBy(dx: 6, dy: 6)

            squarify(nodes: sorted, totalSize: totalSize, in: rect, context: &context, depth: 0)
        }
        .frame(width: size.width, height: size.height)
        .id(version)
    }

    private func squarify(nodes: [FileNode], totalSize: Int64, in rect: CGRect, context: inout GraphicsContext, depth: Int) {
        guard !nodes.isEmpty, rect.width > 2, rect.height > 2 else { return }

        if nodes.count == 1 {
            drawNode(nodes[0], in: rect, context: &context, depth: depth)
            return
        }

        let isWide = rect.width >= rect.height
        var offset: CGFloat = 0
        var remaining = nodes
        var remainingTotal = totalSize
        var remainingRect = rect

        while !remaining.isEmpty {
            let (row, rest) = splitRow(remaining, for: remainingRect, isWide: isWide, totalSize: remainingTotal)
            guard !row.isEmpty else { break }

            let rowSize = row.reduce(Int64(0)) { $0 + $1.totalSize }
            let rowRatio = CGFloat(rowSize) / CGFloat(remainingTotal)

            let rowRect: CGRect
            if isWide {
                rowRect = CGRect(x: remainingRect.origin.x, y: remainingRect.origin.y, width: remainingRect.width, height: remainingRect.height * rowRatio)
                remainingRect = CGRect(x: remainingRect.origin.x, y: remainingRect.origin.y + rowRect.height, width: remainingRect.width, height: remainingRect.height - rowRect.height)
            } else {
                rowRect = CGRect(x: remainingRect.origin.x, y: remainingRect.origin.y, width: remainingRect.width * rowRatio, height: remainingRect.height)
                remainingRect = CGRect(x: remainingRect.origin.x + rowRect.width, y: remainingRect.origin.y, width: remainingRect.width - rowRect.width, height: remainingRect.height)
            }

            layoutRow(row, rowSize: rowSize, in: rowRect, isWide: !isWide, context: &context, depth: depth)

            remaining = rest
            remainingTotal -= rowSize
        }
    }

    private func splitRow(_ nodes: [FileNode], for rect: CGRect, isWide: Bool, totalSize: Int64) -> (row: [FileNode], rest: [FileNode]) {
        guard !nodes.isEmpty else { return ([], []) }
        var row: [FileNode] = []
        var rowSize: Int64 = 0
        let dimension = isWide ? rect.height : rect.width

        for node in nodes {
            let newRow = row + [node]
            let newRowSize = rowSize + node.totalSize
            let newRatio = worstRatio(newRow, rowSize: newRowSize, totalSize: totalSize, dimension: dimension)
            let oldRatio = worstRatio(row, rowSize: rowSize, totalSize: totalSize, dimension: dimension)
            if row.isEmpty || newRatio <= oldRatio {
                row.append(node)
                rowSize = newRowSize
            } else {
                break
            }
        }
        return (row, Array(nodes.dropFirst(row.count)))
    }

    private func worstRatio(_ nodes: [FileNode], rowSize: Int64, totalSize: Int64, dimension: CGFloat) -> CGFloat {
        guard !nodes.isEmpty, rowSize > 0, totalSize > 0 else { return .infinity }
        let rowLen = dimension * CGFloat(rowSize) / CGFloat(totalSize)
        var worst: CGFloat = 0
        for node in nodes {
            let nodeLen = rowLen * CGFloat(node.totalSize) / CGFloat(rowSize)
            let ratio = max(rowLen / nodeLen, nodeLen / rowLen)
            worst = max(worst, ratio)
        }
        return worst
    }

    private func layoutRow(_ nodes: [FileNode], rowSize: Int64, in rect: CGRect, isWide: Bool, context: inout GraphicsContext, depth: Int) {
        guard !nodes.isEmpty, rowSize > 0 else { return }
        var offset: CGFloat = 0
        for node in nodes {
            let ratio = CGFloat(node.totalSize) / CGFloat(rowSize)
            let nodeRect: CGRect
            if isWide {
                let h = rect.height * ratio
                nodeRect = CGRect(x: rect.origin.x, y: rect.origin.y + offset, width: rect.width, height: h)
                offset += h
            } else {
                let w = rect.width * ratio
                nodeRect = CGRect(x: rect.origin.x + offset, y: rect.origin.y, width: w, height: rect.height)
                offset += w
            }
            drawNode(node, in: nodeRect, context: &context, depth: depth)
        }
    }

    private func drawNode(_ node: FileNode, in rect: CGRect, context: inout GraphicsContext, depth: Int) {
        let gap: CGFloat = depth == 0 ? 3 : 1.5
        let r = rect.insetBy(dx: gap / 2, dy: gap / 2)
        guard r.width > 1, r.height > 1 else { return }

        let color = tableauColor(for: node, depth: depth)
        let cornerRadius: CGFloat = depth == 0 ? 8 : 4

        let shape = Path(roundedRect: r, cornerRadius: cornerRadius)
        context.fill(shape, with: .color(color))

        if depth == 0 {
            let darker = color.opacity(0.7)
            context.stroke(shape, with: .color(darker), lineWidth: 1.5)
        } else {
            let lighter = color.opacity(0.5)
            context.stroke(shape, with: .color(lighter), lineWidth: 0.5)
        }

        if r.width > 40 && r.height > 22 {
            let sizeStr = ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file)
            let fontSize: CGFloat = min(14, max(9, r.height * 0.12))
            let nameText = Text(node.name)
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            let sizeText = Text(sizeStr)
                .font(.system(size: fontSize * 0.85, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            context.draw(nameText, at: CGPoint(x: r.origin.x + 8, y: r.origin.y + r.height * 0.35), anchor: .leading)
            context.draw(sizeText, at: CGPoint(x: r.origin.x + 8, y: r.origin.y + r.height * 0.65), anchor: .leading)
        } else if r.width > 24 && r.height > 14 {
            let fontSize: CGFloat = min(10, max(7, r.height * 0.3))
            let nameText = Text(node.name)
                .font(.system(size: fontSize, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            context.draw(nameText, at: CGPoint(x: r.origin.x + 4, y: r.origin.y + r.height * 0.5), anchor: .leading)
        }

        if depth < 2 && node.isDirectory && !node.children.isEmpty && r.width > 30 && r.height > 30 {
            let childSorted = node.children.sorted { $0.totalSize > $1.totalSize }
            let childTotal = node.totalSize
            let inner = r.insetBy(dx: 3, dy: 3)
            if inner.width > 4, inner.height > 4 {
                squarify(nodes: childSorted, totalSize: childTotal, in: inner, context: &context, depth: depth + 1)
            }
        }
    }

    private func tableauColor(for node: FileNode, depth: Int) -> Color {
        let baseColors: [Color] = [
            Color(red: 0.31, green: 0.47, blue: 0.65),
            Color(red: 0.95, green: 0.56, blue: 0.17),
            Color(red: 0.88, green: 0.34, blue: 0.35),
            Color(red: 0.46, green: 0.72, blue: 0.70),
            Color(red: 0.35, green: 0.63, blue: 0.31),
            Color(red: 0.93, green: 0.78, blue: 0.28),
            Color(red: 0.69, green: 0.48, blue: 0.63),
            Color(red: 0.61, green: 0.46, blue: 0.37),
            Color(red: 0.49, green: 0.39, blue: 0.55),
            Color(red: 0.70, green: 0.49, blue: 0.29),
        ]

        if depth == 0 {
            let hash = abs(node.name.hashValue)
            return baseColors[hash % baseColors.count]
        } else {
            let ext = node.fileExtension.lowercased()
            switch ext {
            case "jpg", "jpeg", "png", "gif", "heic", "webp", "tiff", "bmp", "svg":
                return Color(red: 0.95, green: 0.56, blue: 0.17)
            case "mp4", "mov", "avi", "mkv", "wmv", "flv", "webm":
                return Color(red: 0.88, green: 0.34, blue: 0.35)
            case "mp3", "wav", "flac", "aac", "ogg", "m4a":
                return Color(red: 0.46, green: 0.72, blue: 0.70)
            case "pdf", "doc", "docx", "txt", "rtf", "pages":
                return Color(red: 0.31, green: 0.47, blue: 0.65)
            case "zip", "tar", "gz", "dmg", "pkg", "rar", "7z":
                return Color(red: 0.93, green: 0.78, blue: 0.28)
            case "swift", "js", "ts", "py", "rb", "java", "cpp", "c", "h":
                return Color(red: 0.35, green: 0.63, blue: 0.31)
            case "app", "bundle", "framework":
                return Color(red: 0.69, green: 0.48, blue: 0.63)
            case "plist", "json", "xml", "yaml", "yml":
                return Color(red: 0.61, green: 0.46, blue: 0.37)
            default:
                let hash = abs(node.name.hashValue)
                let brightness = Double(depth) * 0.08
                return baseColors[hash % baseColors.count].opacity(1.0 - brightness)
            }
        }
    }
}
