import SwiftUI

struct LiveTreemapCanvas: View {
    let root: FileNode
    let size: CGSize
    let version: Int

    var body: some View {
        Canvas { ctx, cs in
            ctx.fill(Path(CGRect(origin: .zero, size: cs)), with: .color(Color(red: 0.06, green: 0.06, blue: 0.10)))
            let kids = root.children.filter { $0.totalSize > 0 }.sorted { $0.totalSize > $1.totalSize }
            guard !kids.isEmpty else { return }
            let total = kids.reduce(Int64(0)) { $0 + $1.totalSize }
            guard total > 0 else { return }
            squarify(kids, total: total, rect: CGRect(origin: .zero, size: cs).insetBy(dx: 4, dy: 4), ctx: &ctx, depth: 0)
        }
        .frame(width: size.width, height: size.height)
        .id(version)
    }

    private func squarify(_ nodes: [FileNode], total: Int64, rect: CGRect, ctx: inout GraphicsContext, depth: Int) {
        guard !nodes.isEmpty, rect.width > 1, rect.height > 1, total > 0 else { return }
        if nodes.count == 1 { drawBox(nodes[0], in: rect, ctx: &ctx, depth: depth, idx: 0); return }

        var remaining = nodes
        var remTotal = total
        var area = rect

        while !remaining.isEmpty {
            let horizontal = area.width >= area.height
            let side = horizontal ? area.height : area.width

            var bestN = 1
            var bestW = CGFloat.infinity
            var bestT = remaining[0].totalSize

            var sum: Int64 = 0
            for i in 0..<min(remaining.count, 50) {
                sum += remaining[i].totalSize
                let long = side * CGFloat(sum) / CGFloat(remTotal)
                var worst: CGFloat = 0
                for j in 0...i {
                    let s = long * CGFloat(remaining[j].totalSize) / CGFloat(sum)
                    if s > 0 { worst = max(worst, max(long/s, s/long)) }
                }
                if worst <= bestW {
                    bestW = worst
                    bestN = i + 1
                    bestT = sum
                } else if worst > bestW * 1.5 {
                    break
                }
            }

            guard bestT > 0 else { break }
            let frac = CGFloat(bestT) / CGFloat(remTotal)
            let strip: CGRect
            if horizontal {
                let h = area.height * frac
                strip = CGRect(x: area.origin.x, y: area.origin.y, width: area.width, height: h)
                area = CGRect(x: area.origin.x, y: area.origin.y + h, width: area.width, height: area.height - h)
            } else {
                let w = area.width * frac
                strip = CGRect(x: area.origin.x, y: area.origin.y, width: w, height: area.height)
                area = CGRect(x: area.origin.x + w, y: area.origin.y, width: area.width - w, height: area.height)
            }

            let row = Array(remaining.prefix(bestN))
            var off: CGFloat = 0
            for (i, node) in row.enumerated() {
                let f = CGFloat(node.totalSize) / CGFloat(bestT)
                let r: CGRect
                if horizontal {
                    let w = strip.width * f
                    r = CGRect(x: strip.origin.x + off, y: strip.origin.y, width: w, height: strip.height)
                    off += w
                } else {
                    let h = strip.height * f
                    r = CGRect(x: strip.origin.x, y: strip.origin.y + off, width: strip.width, height: h)
                    off += h
                }
                drawBox(node, in: r, ctx: &ctx, depth: depth, idx: i)
            }

            remaining = Array(remaining.dropFirst(bestN))
            remTotal -= bestT
        }
    }

    private func drawBox(_ node: FileNode, in rect: CGRect, ctx: inout GraphicsContext, depth: Int, idx: Int) {
        let g: CGFloat = depth == 0 ? 3 : 1.5
        let r = rect.insetBy(dx: g, dy: g)
        guard r.width > 0.5, r.height > 0.5 else { return }

        let color = pickColor(node: node, depth: depth, idx: idx)
        let rad: CGFloat = depth == 0 ? 10 : 5
        let shape = Path(roundedRect: r, cornerRadius: rad)
        ctx.fill(shape, with: .color(color))
        ctx.stroke(shape, with: .color(.white.opacity(depth == 0 ? 0.15 : 0.08)), lineWidth: depth == 0 ? 1 : 0.5)

        if r.width > 50 && r.height > 28 {
            let fs = min(14, max(9, r.height * 0.13))
            ctx.draw(
                Text(node.name).font(.system(size: fs, weight: .bold, design: .rounded)).foregroundColor(.white),
                at: CGPoint(x: r.minX + 8, y: r.minY + r.height * 0.33), anchor: .leading
            )
            ctx.draw(
                Text(ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file))
                    .font(.system(size: fs * 0.75, weight: .regular, design: .rounded)).foregroundColor(.white.opacity(0.7)),
                at: CGPoint(x: r.minX + 8, y: r.minY + r.height * 0.65), anchor: .leading
            )
        } else if r.width > 26 && r.height > 14 {
            let fs = min(10, max(7, r.height * 0.38))
            ctx.draw(
                Text(node.name).font(.system(size: fs, weight: .semibold, design: .rounded)).foregroundColor(.white),
                at: CGPoint(x: r.minX + 4, y: r.midY), anchor: .leading
            )
        }

        if depth < 2 && node.isDirectory && !node.children.isEmpty && r.width > 16 && r.height > 16 {
            let kids = node.children.filter { $0.totalSize > 0 }.sorted { $0.totalSize > $1.totalSize }
            let ct = kids.reduce(Int64(0)) { $0 + $1.totalSize }
            if ct > 0 {
                let inner = r.insetBy(dx: 2, dy: 2)
                if inner.width > 2, inner.height > 2 {
                    squarify(kids, total: ct, rect: inner, ctx: &ctx, depth: depth + 1)
                }
            }
        }
    }

    private func pickColor(node: FileNode, depth: Int, idx: Int) -> Color {
        let p: [Color] = [
            Color(red: 0.22, green: 0.52, blue: 0.82),
            Color(red: 0.93, green: 0.48, blue: 0.13),
            Color(red: 0.82, green: 0.28, blue: 0.28),
            Color(red: 0.13, green: 0.70, blue: 0.48),
            Color(red: 0.90, green: 0.72, blue: 0.20),
            Color(red: 0.52, green: 0.28, blue: 0.72),
            Color(red: 0.85, green: 0.45, blue: 0.52),
            Color(red: 0.38, green: 0.65, blue: 0.28),
            Color(red: 0.68, green: 0.45, blue: 0.25),
            Color(red: 0.28, green: 0.50, blue: 0.70),
        ]
        if depth == 0 { return p[idx % p.count] }
        let ext = node.fileExtension.lowercased()
        switch ext {
        case "jpg","jpeg","png","gif","heic","webp","tiff","bmp","svg": return p[1]
        case "mp4","mov","avi","mkv","wmv","webm": return p[2]
        case "mp3","wav","flac","aac","ogg","m4a": return p[3]
        case "pdf","doc","docx","txt","rtf","pages","md": return p[0]
        case "zip","tar","gz","dmg","pkg","rar","7z","bz2": return p[4]
        case "swift","js","ts","py","rb","java","cpp","c","h","go","rs": return p[5]
        case "app","bundle","framework","dylib","so": return p[6]
        case "plist","json","xml","yaml","yml","html","css": return p[7]
        default: return p[abs(node.name.hashValue) % p.count]
        }
    }
}
