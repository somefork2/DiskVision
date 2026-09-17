import SwiftUI

struct LiveTreemapCanvas: View {
    let root: FileNode
    let size: CGSize
    let version: Int

    var body: some View {
        Canvas { ctx, cs in
            ctx.fill(Path(CGRect(origin: .zero, size: cs)), with: .color(Color(red: 0.07, green: 0.07, blue: 0.12)))

            let kids = root.children.filter { $0.totalSize > 0 }.sorted { $0.totalSize > $1.totalSize }
            guard !kids.isEmpty else { return }
            let total = kids.reduce(Int64(0)) { $0 + $1.totalSize }
            guard total > 0 else { return }

            drawTreemap(kids, total: total, in: CGRect(origin: .zero, size: cs).insetBy(dx: 3, dy: 3), ctx: &ctx, depth: 0)
        }
        .frame(width: size.width, height: size.height)
        .id(version)
    }

    private func drawTreemap(_ nodes: [FileNode], total: Int64, in rect: CGRect, ctx: inout GraphicsContext, depth: Int) {
        guard !nodes.isEmpty, rect.width > 2, rect.height > 2 else { return }

        var items = nodes
        var remaining = total
        var r = rect

        while !items.isEmpty {
            let horiz = r.width >= r.height
            let short = horiz ? r.height : r.width

            var best: [FileNode] = []
            var bestTotal: Int64 = 0
            var bestWorst: CGFloat = .greatestFiniteMagnitude

            var row: [FileNode] = []
            var rowTotal: Int64 = 0

            for item in items {
                let newRow = row + [item]
                let newTotal = rowTotal + item.totalSize
                let w = calcWorst(row: newRow, rowTotal: newTotal, total: remaining, short: short)
                if w <= bestWorst {
                    bestWorst = w
                    best = newRow
                    bestTotal = newTotal
                    row = newRow
                    rowTotal = newTotal
                } else {
                    break
                }
            }

            guard !best.isEmpty, bestTotal > 0 else { break }

            let frac = CGFloat(bestTotal) / CGFloat(remaining)
            let rowRect: CGRect
            if horiz {
                let h = r.height * frac
                rowRect = CGRect(x: r.origin.x, y: r.origin.y, width: r.width, height: h)
                r = CGRect(x: r.origin.x, y: r.origin.y + h, width: r.width, height: r.height - h)
            } else {
                let w = r.width * frac
                rowRect = CGRect(x: r.origin.x, y: r.origin.y, width: w, height: r.height)
                r = CGRect(x: r.origin.x + w, y: r.origin.y, width: r.width - w, height: r.height)
            }

            layoutSlices(best, total: bestTotal, in: rowRect, horiz: !horiz, ctx: &ctx, depth: depth)

            items = Array(items.dropFirst(best.count))
            remaining -= bestTotal
        }
    }

    private func calcWorst(row: [FileNode], rowTotal: Int64, total: Int64, short: CGFloat) -> CGFloat {
        guard !row.isEmpty, rowTotal > 0, total > 0 else { return 10000 }
        let long = short * CGFloat(rowTotal) / CGFloat(total)
        var worst: CGFloat = 0
        for n in row {
            let side = long * CGFloat(n.totalSize) / CGFloat(rowTotal)
            if side > 0 {
                worst = max(worst, long / side, side / long)
            }
        }
        return worst
    }

    private func layoutSlices(_ nodes: [FileNode], total: Int64, in rect: CGRect, horiz: Bool, ctx: inout GraphicsContext, depth: Int) {
        var offset: CGFloat = 0
        for (i, node) in nodes.enumerated() {
            let frac = CGFloat(node.totalSize) / CGFloat(total)
            let r: CGRect
            if horiz {
                let w = rect.width * frac
                r = CGRect(x: rect.origin.x + offset, y: rect.origin.y, width: w, height: rect.height)
                offset += w
            } else {
                let h = rect.height * frac
                r = CGRect(x: rect.origin.x, y: rect.origin.y + offset, width: rect.width, height: h)
                offset += h
            }
            drawNode(node, in: r, ctx: &ctx, depth: depth, index: i)
        }
    }

    private func drawNode(_ node: FileNode, in rect: CGRect, ctx: inout GraphicsContext, depth: Int, index: Int) {
        let gap: CGFloat = depth == 0 ? 3 : 1.5
        let r = rect.insetBy(dx: gap, dy: gap)
        guard r.width > 0.5, r.height > 0.5 else { return }

        let color = pickColor(node: node, depth: depth, index: index)
        let rad: CGFloat = depth == 0 ? 10 : 4

        let shape = Path(roundedRect: r, cornerRadius: rad)
        ctx.fill(shape, with: .color(color))
        ctx.stroke(shape, with: .color(color.opacity(0.5)), lineWidth: depth == 0 ? 1.5 : 0.5)

        if r.width > 50 && r.height > 28 {
            let fs = min(14, max(9, r.height * 0.13))
            let nameT = Text(node.name).font(.system(size: fs, weight: .bold, design: .rounded)).foregroundColor(.white)
            let sizeT = Text(ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file))
                .font(.system(size: fs * 0.8, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.75))
            ctx.draw(nameT, at: CGPoint(x: r.minX + 8, y: r.minY + r.height * 0.35), anchor: .leading)
            ctx.draw(sizeT, at: CGPoint(x: r.minX + 8, y: r.minY + r.height * 0.65), anchor: .leading)
        } else if r.width > 26 && r.height > 14 {
            let fs = min(10, max(7, r.height * 0.4))
            let nameT = Text(node.name).font(.system(size: fs, weight: .semibold, design: .rounded)).foregroundColor(.white)
            ctx.draw(nameT, at: CGPoint(x: r.minX + 4, y: r.midY), anchor: .center)
        }

        if depth < 2 && node.isDirectory && !node.children.isEmpty && r.width > 16 && r.height > 16 {
            let kids = node.children.filter { $0.totalSize > 0 }.sorted { $0.totalSize > $1.totalSize }
            let childTotal = kids.reduce(Int64(0)) { $0 + $1.totalSize }
            if childTotal > 0 {
                let inner = r.insetBy(dx: 2, dy: 2)
                if inner.width > 2, inner.height > 2 {
                    drawTreemap(kids, total: childTotal, in: inner, ctx: &ctx, depth: depth + 1)
                }
            }
        }
    }

    private func pickColor(node: FileNode, depth: Int, index: Int) -> Color {
        let palette: [Color] = [
            Color(red: 0.24, green: 0.55, blue: 0.85),
            Color(red: 0.95, green: 0.50, blue: 0.15),
            Color(red: 0.85, green: 0.30, blue: 0.30),
            Color(red: 0.15, green: 0.72, blue: 0.50),
            Color(red: 0.92, green: 0.75, blue: 0.22),
            Color(red: 0.55, green: 0.30, blue: 0.75),
            Color(red: 0.88, green: 0.48, blue: 0.55),
            Color(red: 0.40, green: 0.68, blue: 0.30),
            Color(red: 0.70, green: 0.48, blue: 0.28),
            Color(red: 0.30, green: 0.52, blue: 0.72),
        ]

        if depth == 0 {
            return palette[index % palette.count]
        }

        let ext = node.fileExtension.lowercased()
        switch ext {
        case "jpg","jpeg","png","gif","heic","webp","tiff","bmp","svg":
            return palette[1]
        case "mp4","mov","avi","mkv","wmv","webm":
            return palette[2]
        case "mp3","wav","flac","aac","ogg","m4a":
            return palette[3]
        case "pdf","doc","docx","txt","rtf","pages","md":
            return palette[0]
        case "zip","tar","gz","dmg","pkg","rar","7z","bz2":
            return palette[4]
        case "swift","js","ts","py","rb","java","cpp","c","h","go","rs":
            return palette[5]
        case "app","bundle","framework","dylib","so":
            return palette[6]
        case "plist","json","xml","yaml","yml","html","css":
            return palette[7]
        default:
            return palette[(abs(node.name.hashValue) % palette.count)]
        }
    }
}
