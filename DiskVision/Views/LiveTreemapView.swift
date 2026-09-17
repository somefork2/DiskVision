import SwiftUI

struct LiveTreemapView: NSViewRepresentable {
    let root: FileNode
    let size: CGSize
    let colorMapper: FileColorMapper
    let version: Int

    func makeNSView(context: Context) -> LiveTreemapNSView {
        LiveTreemapNSView()
    }

    func updateNSView(_ nsView: LiveTreemapNSView, context: Context) {
        nsView.root = root
        nsView.viewSize = size
        nsView.colorMapper = colorMapper
        nsView.needsDisplay = true
    }
}

class LiveTreemapNSView: NSView {
    var root: FileNode?
    var viewSize: CGSize = .zero
    var colorMapper = FileColorMapper(mapping: .fileSize, palette: .vivid)

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let root = root, viewSize.width > 10, viewSize.height > 10 else {
            NSColor.windowBackgroundColor.setFill()
            dirtyRect.fill()
            return
        }

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.setFillColor(NSColor.windowBackgroundColor.cgColor)
        ctx.fill(bounds)

        let children = root.children.filter { $0.totalSize > 0 }
        guard !children.isEmpty else { return }

        let totalSize = children.reduce(Int64(0)) { $0 + $1.totalSize }
        guard totalSize > 0 else { return }

        let sorted = children.sorted { $0.totalSize > $1.totalSize }
        let rect = CGRect(origin: .zero, size: viewSize).insetBy(dx: 1, dy: 1)

        var x = rect.origin.x
        var y = rect.origin.y
        let w = rect.width
        let h = rect.height

        for node in sorted {
            let ratio = Double(node.totalSize) / Double(totalSize)
            let area = Double(w) * Double(h) * ratio
            let side = sqrt(area)

            let nodeW: CGFloat
            let nodeH: CGFloat
            if w >= h {
                nodeH = h
                nodeW = CGFloat(area) / h
            } else {
                nodeW = w
                nodeH = CGFloat(area) / w
            }

            let r = CGRect(x: x, y: y, width: nodeW, height: nodeH)

            if let cgColor = colorMapper.color(for: node, context: ColorContext(
                maxSize: totalSize, maxDepth: 2, earliestDate: Date.distantPast, latestDate: Date()
            )).cgColor {
                ctx.setFillColor(cgColor)
            }
            ctx.fill(r)

            ctx.setStrokeColor(NSColor.windowBackgroundColor.cgColor)
            ctx.setLineWidth(1)
            ctx.stroke(r)

            if r.width > 30 && r.height > 16 {
                let fs = min(12, r.height * 0.12)
                let sizeStr = ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file)
                let label = "\(node.name) — \(sizeStr)" as NSString
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: fs, weight: .semibold),
                    .foregroundColor: NSColor.white
                ]
                label.draw(in: r.insetBy(dx: 4, dy: 3), withAttributes: attrs)
            }

            if w >= h { x += nodeW } else { y += nodeH }
        }
    }
}
