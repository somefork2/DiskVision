import SwiftUI

struct LiveTreemapCanvas: View {
    let root: FileNode
    let size: CGSize
    let version: Int

    private let colors: [Color] = [
        Color(red: 0.20, green: 0.60, blue: 0.86),
        Color(red: 0.90, green: 0.49, blue: 0.13),
        Color(red: 0.83, green: 0.33, blue: 0.33),
        Color(red: 0.18, green: 0.74, blue: 0.56),
        Color(red: 0.93, green: 0.78, blue: 0.25),
        Color(red: 0.56, green: 0.27, blue: 0.68),
        Color(red: 0.89, green: 0.50, blue: 0.55),
        Color(red: 0.42, green: 0.65, blue: 0.32),
        Color(red: 0.70, green: 0.50, blue: 0.30),
        Color(red: 0.35, green: 0.55, blue: 0.75),
        Color(red: 0.60, green: 0.80, blue: 0.40),
        Color(red: 0.95, green: 0.65, blue: 0.30),
    ]

    var body: some View {
        Canvas { ctx, canvasSize in
            ctx.fill(Path(CGRect(origin: .zero, size: canvasSize)), with: .color(Color(red: 0.08, green: 0.08, blue: 0.14)))

            let children = root.children.filter { $0.totalSize > 0 }.sorted { $0.totalSize > $1.totalSize }
            guard !children.isEmpty else { return }

            let total = children.reduce(Int64(0)) { $0 + $1.totalSize }
            guard total > 0 else { return }

            let rect = CGRect(origin: .zero, size: canvasSize).insetBy(dx: 4, dy: 4)
            render(children, total: total, in: rect, ctx: &ctx, depth: 0)
        }
        .frame(width: size.width, height: size.height)
        .id(version)
    }

    private func render(_ nodes: [FileNode], total: Int64, in rect: CGRect, ctx: inout GraphicsContext, depth: Int) {
        guard !nodes.isEmpty, rect.width > 3, rect.height > 3 else { return }

        var remaining = nodes
        var remTotal = total
        var remRect = rect
        let horizontal = rect.width >= rect.height

        while !remaining.isEmpty {
            let (row, rest, rowTotal) = bestRow(remaining, total: remTotal, in: remRect, horizontal: horizontal)
            guard !row.isEmpty, rowTotal > 0 else { break }

            let rowFrac = CGFloat(rowTotal) / CGFloat(remTotal)
            let rowRect: CGRect
            if horizontal {
                let h = remRect.height * rowFrac
                rowRect = CGRect(x: remRect.origin.x, y: remRect.origin.y, width: remRect.width, height: h)
                remRect = CGRect(x: remRect.origin.x, y: remRect.origin.y + h, width: remRect.width, height: remRect.height - h)
            } else {
                let w = remRect.width * rowFrac
                rowRect = CGRect(x: remRect.origin.x, y: remRect.origin.y, width: w, height: remRect.height)
                remRect = CGRect(x: remRect.origin.x + w, y: remRect.origin.y, width: remRect.width - w, height: remRect.height)
            }

            slice(row, total: rowTotal, in: rowRect, horizontal: !horizontal, ctx: &ctx, depth: depth)
            remaining = rest
            remTotal -= rowTotal
        }
    }

    private func bestRow(_ nodes: [FileNode], total: Int64, in rect: CGRect, horizontal: Bool) -> (row: [FileNode], rest: [FileNode], rowTotal: Int64) {
        guard !nodes.isEmpty else { return ([], [], 0) }
        let dim = horizontal ? rect.height : rect.width
        var row: [FileNode] = []
        var rowTotal: Int64 = 0

        for node in nodes {
            let newRow = row + [node]
            let newTotal = rowTotal + node.totalSize
            let newWorst = worst(row: newRow, rowTotal: newTotal, total: total, dim: dim)
            let oldWorst = worst(row: row, rowTotal: rowTotal, total: total, dim: dim)
            if row.isEmpty || newWorst <= oldWorst {
                row.append(node)
                rowTotal = newTotal
            } else {
                break
            }
        }
        return (row, Array(nodes.dropFirst(row.count)), rowTotal)
    }

    private func worst(row: [FileNode], rowTotal: Int64, total: Int64, dim: CGFloat) -> CGFloat {
        guard !row.isEmpty, rowTotal > 0, total > 0 else { return 1000 }
        let len = dim * CGFloat(rowTotal) / CGFloat(total)
        var w: CGFloat = 0
        for n in row {
            let side = len * CGFloat(n.totalSize) / CGFloat(rowTotal)
            w = max(w, max(len / side, side / len))
        }
        return w
    }

    private func slice(_ nodes: [FileNode], total: Int64, in rect: CGRect, horizontal: Bool, ctx: inout GraphicsContext, depth: Int) {
        guard !nodes.isEmpty, total > 0 else { return }
        var offset: CGFloat = 0
        for (i, node) in nodes.enumerated() {
            let frac = CGFloat(node.totalSize) / CGFloat(total)
            let r: CGRect
            if horizontal {
                let w = rect.width * frac
                r = CGRect(x: rect.origin.x + offset, y: rect.origin.y, width: w, height: rect.height)
                offset += w
            } else {
                let h = rect.height * frac
                r = CGRect(x: rect.origin.x, y: rect.origin.y + offset, width: rect.width, height: h)
                offset += h
            }
            draw(node, in: r, ctx: &ctx, depth: depth, index: i)
        }
    }

    private func draw(_ node: FileNode, in rect: CGRect, ctx: inout GraphicsContext, depth: Int, index: Int) {
        let gap: CGFloat = depth == 0 ? 2.5 : 1.5
        let r = rect.insetBy(dx: gap, dy: gap)
        guard r.width > 1, r.height > 1 else { return }

        let color = colorFor(node, depth: depth, index: index)
        let radius: CGFloat = depth == 0 ? 10 : 5

        let shape = Path(roundedRect: r, cornerRadius: radius)
        ctx.fill(shape, with: .color(color))

        ctx.stroke(shape, with: .color(color.opacity(0.6)), lineWidth: 1)

        if r.width > 50 && r.height > 28 {
            let fs = min(15, max(10, r.height * 0.14))
            let name = Text(node.name)
                .font(.system(size: fs, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            let sizeStr = ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file)
            let size = Text(sizeStr)
                .font(.system(size: fs * 0.8, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            ctx.draw(name, at: CGPoint(x: r.origin.x + 8, y: r.origin.y + r.height * 0.35), anchor: .leading)
            ctx.draw(size, at: CGPoint(x: r.origin.x + 8, y: r.origin.y + r.height * 0.65), anchor: .leading)
        } else if r.width > 28 && r.height > 16 {
            let fs = min(11, max(8, r.height * 0.35))
            let name = Text(node.name)
                .font(.system(size: fs, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            ctx.draw(name, at: CGPoint(x: r.origin.x + 5, y: r.origin.y + r.height * 0.5), anchor: .leading)
        }

        if depth < 2 && node.isDirectory && !node.children.isEmpty && r.width > 20 && r.height > 20 {
            let children = node.children.filter { $0.totalSize > 0 }.sorted { $0.totalSize > $1.totalSize }
            let childTotal = children.reduce(Int64(0)) { $0 + $1.totalSize }
            if childTotal > 0 {
                let inner = r.insetBy(dx: 2, dy: 2)
                if inner.width > 3, inner.height > 3 {
                    render(children, total: childTotal, in: inner, ctx: &ctx, depth: depth + 1)
                }
            }
        }
    }

    private func colorFor(_ node: FileNode, depth: Int, index: Int) -> Color {
        if depth == 0 {
            return colors[index % colors.count]
        }

        let ext = node.fileExtension.lowercased()
        let extColors: [String: Color] = [
            "jpg": colors[1], "jpeg": colors[1], "png": colors[1], "gif": colors[1], "heic": colors[1], "webp": colors[1],
            "mp4": colors[2], "mov": colors[2], "avi": colors[2], "mkv": colors[2],
            "mp3": colors[3], "wav": colors[3], "flac": colors[3], "aac": colors[3],
            "pdf": colors[0], "doc": colors[0], "docx": colors[0], "txt": colors[0],
            "zip": colors[4], "tar": colors[4], "gz": colors[4], "dmg": colors[4],
            "swift": colors[5], "js": colors[5], "py": colors[5], "rb": colors[5],
            "app": colors[6], "bundle": colors[6],
        ]

        if let c = extColors[ext] {
            return c.opacity(0.9 - Double(depth) * 0.1)
        }

        return colors[(abs(node.name.hashValue) + depth * 3) % colors.count].opacity(0.85 - Double(depth) * 0.1)
    }
}
