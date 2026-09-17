import SwiftUI
import AppKit

class TreemapRenderer {
    static func render(
        nodes: [FileNode],
        in rect: CGRect,
        colorMapper: FileColorMapper,
        colorContext: ColorContext,
        selectedNode: FileNode?,
        hoveredNode: FileNode?
    ) -> [RenderedRect] {
        var result: [RenderedRect] = []
        renderNodes(
            nodes: nodes,
            in: rect,
            colorMapper: colorMapper,
            colorContext: colorContext,
            selectedNode: selectedNode,
            hoveredNode: hoveredNode,
            result: &result
        )
        return result
    }

    private static func renderNodes(
        nodes: [FileNode],
        in rect: CGRect,
        colorMapper: FileColorMapper,
        colorContext: ColorContext,
        selectedNode: FileNode?,
        hoveredNode: FileNode?,
        result: inout [RenderedRect]
    ) {
        for node in nodes {
            guard node.isVisible, !node.isFiltered else { continue }
            guard node.layoutRect.width > 0.5, node.layoutRect.height > 0.5 else { continue }

            let color = colorMapper.color(for: node, context: colorContext)
            let isSelected = node.id == selectedNode?.id
            let isHovered = node.id == hoveredNode?.id

            let renderedRect = RenderedRect(
                frame: node.layoutRect,
                color: color,
                isSelected: isSelected,
                isHovered: isHovered,
                node: node
            )
            result.append(renderedRect)

            if node.isDirectory && !node.children.isEmpty {
                let childRect = node.layoutRect.insetBy(dx: 2, dy: 2)
                guard childRect.width > 1, childRect.height > 1 else { continue }
                renderNodes(
                    nodes: node.children,
                    in: childRect,
                    colorMapper: colorMapper,
                    colorContext: colorContext,
                    selectedNode: selectedNode,
                    hoveredNode: hoveredNode,
                    result: &result
                )
            }
        }
    }

    static func hitTest(
        point: CGPoint,
        in nodes: [FileNode]
    ) -> FileNode? {
        for node in nodes.reversed() {
            guard node.isVisible, !node.isFiltered else { continue }

            if node.isDirectory && !node.children.isEmpty {
                if let child = hitTest(point: point, in: node.children) {
                    return child
                }
            }

            if node.layoutRect.contains(point) {
                return node
            }
        }
        return nil
    }

    static func exportImage(
        nodes: [FileNode],
        size: CGSize,
        colorMapper: FileColorMapper,
        colorContext: ColorContext
    ) -> NSImage? {
        let rect = CGRect(origin: .zero, size: size)

        TreemapLayout.layout(nodes: nodes, in: rect, padding: 0, minWidth: 1, minHeight: 1)

        let rendered = render(
            nodes: nodes,
            in: rect,
            colorMapper: colorMapper,
            colorContext: colorContext,
            selectedNode: nil,
            hoveredNode: nil
        )

        let image = NSImage(size: size)
        image.lockFocus()

        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }

        context.setFillColor(NSColor.windowBackgroundColor.cgColor)
        context.fill(rect)

        for r in rendered {
            if let cgColor = r.color.cgColor {
                context.setFillColor(cgColor)
            }
            context.fill(r.frame)

            context.setStrokeColor(NSColor.separatorColor.cgColor)
            context.setLineWidth(0.5)
            context.stroke(r.frame)

            if r.frame.width > 40 && r.frame.height > 20 {
                let fontSize: CGFloat = min(11, r.frame.height * 0.4)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: fontSize),
                    .foregroundColor: NSColor.white
                ]
                let labelRect = r.frame.insetBy(dx: 3, dy: 2)
                (r.node.name as NSString).draw(in: labelRect, withAttributes: attrs)
            }
        }

        image.unlockFocus()
        return image
    }
}

struct RenderedRect {
    let frame: CGRect
    let color: Color
    let isSelected: Bool
    let isHovered: Bool
    let node: FileNode
}
