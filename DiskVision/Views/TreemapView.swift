import SwiftUI

struct TreemapView: NSViewRepresentable {
    @EnvironmentObject var viewModel: FileScannerViewModel
    let nodes: [FileNode]
    let size: CGSize

    func makeNSView(context: Context) -> TreemapNSView {
        let view = TreemapNSView()
        view.viewModel = viewModel
        view.nodes = nodes
        view.onNodeSelected = { node in
            viewModel.selectNode(node)
        }
        view.onNodeDoubleClicked = { node in
            viewModel.navigateInto(node)
        }
        return view
    }

    func updateNSView(_ nsView: TreemapNSView, context: Context) {
        nsView.viewModel = viewModel
        nsView.nodes = nodes
        nsView.needsDisplay = true
    }
}

class TreemapNSView: NSView {
    var viewModel: FileScannerViewModel?
    var nodes: [FileNode] = []
    var onNodeSelected: ((FileNode?) -> Void)?
    var onNodeDoubleClicked: ((FileNode) -> Void)?

    private var hoveredNode: FileNode?
    private var renderedRects: [RenderedRect] = []

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let viewModel = viewModel else { return }

        let rect = bounds

        TreemapLayout.layout(
            nodes: nodes,
            in: rect,
            padding: 1,
            minWidth: 2,
            minHeight: 2
        )

        renderedRects = TreemapRenderer.render(
            nodes: nodes,
            in: rect,
            colorMapper: viewModel.colorMapper,
            colorContext: viewModel.colorContext,
            selectedNode: viewModel.selectedNode,
            hoveredNode: hoveredNode
        )

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.setFillColor(NSColor.windowBackgroundColor.cgColor)
        context.fill(rect)

        for rendered in renderedRects {
            drawRect(rendered, in: context)
        }
    }

    private func drawRect(_ rendered: RenderedRect, in context: CGContext) {
        let rect = rendered.frame

        // Fill
        if let cgColor = rendered.color.cgColor {
            context.setFillColor(cgColor)
        }
        context.fill(rect)

        // Border
        if rendered.isSelected {
            context.setStrokeColor(NSColor.white.cgColor)
            context.setLineWidth(3)
        } else if rendered.isHovered {
            context.setStrokeColor(NSColor.white.withAlphaComponent(0.8).cgColor)
            context.setLineWidth(2)
        } else {
            context.setStrokeColor(NSColor.separatorColor.cgColor)
            context.setLineWidth(0.5)
        }
        context.stroke(rect)

        // Label
        let fontSize: CGFloat = min(11, max(8, rect.height * 0.35))
        guard fontSize >= 7, rect.width > 30, rect.height > 12 else { return }

        let node = rendered.node
        let sizeStr = ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file)
        let label = "\(node.name) — \(sizeStr)"

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: NSColor.white,
            .shadow: {
                let shadow = NSShadow()
                shadow.shadowColor = NSColor.black.withAlphaComponent(0.7)
                shadow.shadowOffset = NSSize(width: 0, height: -1)
                shadow.shadowBlurRadius = 2
                return shadow
            }()
        ]

        let labelRect = rect.insetBy(dx: 4, dy: 2)
        (label as NSString).draw(
            in: labelRect,
            withAttributes: attrs
        )
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let hitNode = TreemapRenderer.hitTest(point: point, in: nodes)
        onNodeSelected?(hitNode)
        needsDisplay = true
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let hitNode = TreemapRenderer.hitTest(point: point, in: nodes)

        if hitNode?.id != hoveredNode?.id {
            hoveredNode = hitNode
            if hitNode != nil {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.arrow.pop()
            }
            needsDisplay = true
        }

        if let node = hitNode {
            updateTooltip(for: node)
        } else {
            clearTooltip()
        }
    }

    override func mouseExited(with event: NSEvent) {
        hoveredNode = nil
        NSCursor.arrow.pop()
        clearTooltip()
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let hitNode = TreemapRenderer.hitTest(point: point, in: nodes), hitNode.isDirectory {
            if event.clickCount == 2 {
                onNodeDoubleClicked?(hitNode)
            }
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 { // Enter
            if let selected = viewModel?.selectedNode, selected.isDirectory {
                onNodeDoubleClicked?(selected)
            }
        } else if event.keyCode == 53 { // Escape
            viewModel?.navigateUp()
        } else {
            super.keyDown(with: event)
        }
    }

    private func updateTooltip(for node: FileNode) {
        let sizeStr = ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file)
        let modStr = node.modificationDate.formatted(date: .abbreviated, time: .shortened)

        var tooltip = "\(node.name)\n"
        tooltip += "Size: \(sizeStr)\n"
        tooltip += "Path: \(node.path)\n"
        tooltip += "Modified: \(modStr)"

        if node.isDirectory {
            tooltip += "\nItems: \(node.children.count)"
        }

        self.toolTip = tooltip
    }

    func clearTooltip() {
        self.toolTip = nil
    }
}
