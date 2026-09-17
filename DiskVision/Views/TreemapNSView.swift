import SwiftUI

struct TreemapNSViewRepresentable: NSViewRepresentable {
    let root: FileNode
    let size: CGSize
    let colorMapper: FileColorMapper
    let version: Int

    func makeNSView(context: Context) -> TreemapDrawingView {
        TreemapDrawingView()
    }

    func updateNSView(_ nsView: TreemapDrawingView, context: Context) {
        nsView.root = root
        nsView.viewSize = size
        nsView.colorMapper = colorMapper
        nsView.needsDisplay = true
    }
}

class TreemapDrawingView: NSView {
    var root: FileNode?
    var viewSize: CGSize = .zero
    var colorMapper = FileColorMapper(mapping: .fileSize, palette: .vivid)

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext, let root = root else { return }
        guard viewSize.width > 10, viewSize.height > 10 else { return }

        // Light background like GrandPerspective
        ctx.setFillColor(NSColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1).cgColor)
        ctx.fill(bounds)

        let rect = CGRect(origin: .zero, size: viewSize).insetBy(dx: 2, dy: 2)
        let colorCtx = ColorContext(maxSize: max(root.totalSize, 1), maxDepth: 5, earliestDate: Date.distantPast, latestDate: Date())

        drawNode(root, in: rect, ctx: ctx, colorCtx: colorCtx, depth: 0, index: 0)
    }

    private func drawNode(_ node: FileNode, in rect: CGRect, ctx: CGContext, colorCtx: ColorContext, depth: Int, index: Int) {
        let gap: CGFloat = depth == 0 ? 1 : 0.5
        let r = rect.insetBy(dx: gap, dy: gap)
        guard r.width > 0.5, r.height > 0.5 else { return }

        let color = colorMapper.color(for: node, context: colorCtx)
        let path = CGPath(rect: r, transform: nil) // GrandPerspective uses sharp corners

        ctx.addPath(path)
        ctx.setFillColor(color.cgColor ?? CGColor(gray: 0.7, alpha: 1))
        ctx.fillPath()

        // Subtle border like GrandPerspective
        ctx.addPath(path)
        ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: depth == 0 ? 0.6 : 0.3))
        ctx.setLineWidth(depth == 0 ? 1 : 0.5)
        ctx.strokePath()

        // Label if space permits
        if r.width > 45 && r.height > 20 {
            let fs = min(12, max(9, r.height * 0.12))
            drawLabel(node.name, in: r, ctx: ctx, fontSize: fs, bold: true, yOffset: r.height * 0.35)
            let sizeStr = ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file)
            drawLabel(sizeStr, in: r, ctx: ctx, fontSize: fs * 0.8, bold: false, yOffset: r.height * 0.65)
        } else if r.width > 24 && r.height > 12 {
            let fs = min(9, max(7, r.height * 0.35))
            drawLabel(node.name, in: r, ctx: ctx, fontSize: fs, bold: false, yOffset: r.height * 0.5)
        }

        // Recurse for directories
        if depth < 2 && node.isDirectory && !node.children.isEmpty && r.width > 14 && r.height > 14 {
            let sorted = node.sortedChildren(by: .sizeDesc)
            let childTotal = sorted.reduce(Int64(0)) { $0 + $1.totalSize }
            guard childTotal > 0 else { return }
            let inner = r.insetBy(dx: 1, dy: 1)
            guard inner.width > 2, inner.height > 2 else { return }
            squarify(sorted, total: childTotal, in: inner, ctx: ctx, colorCtx: colorCtx, depth: depth + 1)
        }
    }

    private func squarify(_ nodes: [FileNode], total: Int64, in rect: CGRect, ctx: CGContext, colorCtx: ColorContext, depth: Int) {
        guard !nodes.isEmpty, total > 0, rect.width > 1, rect.height > 1 else { return }

        var remaining = nodes
        var remTotal = total
        var area = rect
        var idx = 0

        while !remaining.isEmpty {
            let horizontal = area.width >= area.height
            let short = horizontal ? area.height : area.width

            var bestN = 1
            var bestW: CGFloat = .infinity
            var bestT = remaining[0].totalSize

            var sum: Int64 = 0
            for i in 0..<min(remaining.count, 60) {
                sum += remaining[i].totalSize
                let rowLen = short * CGFloat(sum) / CGFloat(remTotal)
                var worst: CGFloat = 0
                for j in 0...i {
                    let s = rowLen * CGFloat(remaining[j].totalSize) / CGFloat(sum)
                    if s > 0 { worst = max(worst, rowLen / s, s / rowLen) }
                }
                if worst <= bestW {
                    bestW = worst
                    bestN = i + 1
                    bestT = sum
                } else if worst > bestW * 2 {
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
            for node in row {
                let f = CGFloat(node.totalSize) / CGFloat(bestT)
                let nr: CGRect
                if horizontal {
                    let w = strip.width * f
                    nr = CGRect(x: strip.origin.x + off, y: strip.origin.y, width: w, height: strip.height)
                    off += w
                } else {
                    let h = strip.height * f
                    nr = CGRect(x: strip.origin.x, y: strip.origin.y + off, width: strip.width, height: h)
                    off += h
                }
                drawNode(node, in: nr, ctx: ctx, colorCtx: colorCtx, depth: depth, index: idx)
                idx += 1
            }

            remaining = Array(remaining.dropFirst(bestN))
            remTotal -= bestT
        }
    }

    private func drawLabel(_ text: String, in rect: CGRect, ctx: CGContext, fontSize: CGFloat, bold: Bool, yOffset: CGFloat) {
        let font = NSFont.systemFont(ofSize: fontSize, weight: bold ? .semibold : .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black // Black text for light background
        ]
        let nsStr = text as NSString
        let labelRect = CGRect(x: rect.minX + 4, y: rect.minY + yOffset - fontSize * 0.5, width: rect.width - 8, height: fontSize * 1.5)
        nsStr.draw(in: labelRect, withAttributes: attrs)
    }
}
