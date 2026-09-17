import Foundation
import CoreGraphics

struct TreemapLayout {
    static func layout(
        nodes: [FileNode],
        in rect: CGRect,
        padding: CGFloat = 1.0,
        minWidth: CGFloat = 2.0,
        minHeight: CGFloat = 2.0
    ) {
        guard !nodes.isEmpty else { return }

        let totalSize = nodes.reduce(Int64(0)) { $0 + $1.totalSize }
        guard totalSize > 0 else { return }

        let availableRect = rect.insetBy(dx: padding, dy: padding)
        guard availableRect.width > 0, availableRect.height > 0 else { return }

        squarify(
            nodes: nodes,
            totalSize: totalSize,
            into: availableRect,
            minWidth: minWidth,
            minHeight: minHeight
        )
    }

    private static func squarify(
        nodes: [FileNode],
        totalSize: Int64,
        into rect: CGRect,
        minWidth: CGFloat,
        minHeight: CGFloat
    ) {
        guard !nodes.isEmpty else { return }

        if nodes.count == 1 {
            let node = nodes[0]
            node.layoutRect = CGRect(
                x: rect.origin.x,
                y: rect.origin.y,
                width: max(rect.width, minWidth),
                height: max(rect.height, minHeight)
            )
            if node.isDirectory && !node.children.isEmpty {
                let childRect = node.layoutRect.insetBy(dx: 2, dy: 2)
                let sorted = node.sortedChildren(by: .sizeDesc)
                squarify(
                    nodes: sorted,
                    totalSize: node.totalSize,
                    into: childRect,
                    minWidth: minWidth,
                    minHeight: minHeight
                )
            }
            return
        }

        let sorted = nodes.sorted { $0.totalSize > $1.totalSize }
        let isHorizontal = rect.width >= rect.height

        layoutRow(
            nodes: sorted,
            totalSize: totalSize,
            in: rect,
            isHorizontal: isHorizontal,
            minWidth: minWidth,
            minHeight: minHeight
        )
    }

    private static func layoutRow(
        nodes: [FileNode],
        totalSize: Int64,
        in rect: CGRect,
        isHorizontal: Bool,
        minWidth: CGFloat,
        minHeight: CGFloat
    ) {
        guard !nodes.isEmpty, totalSize > 0 else { return }

        var remaining = nodes
        var currentRect = rect
        var remainingTotal = totalSize

        while !remaining.isEmpty {
            let (row, rest) = splitRow(remaining, for: currentRect, isHorizontal: isHorizontal)
            guard !row.isEmpty else { break }

            let rowSize = row.reduce(Int64(0)) { $0 + $1.totalSize }
            let rowRatio = Double(rowSize) / Double(remainingTotal)

            let rowRect: CGRect
            if isHorizontal {
                let rowWidth = currentRect.width * CGFloat(rowRatio)
                rowRect = CGRect(
                    x: currentRect.origin.x,
                    y: currentRect.origin.y,
                    width: rowWidth,
                    height: currentRect.height
                )
                currentRect = CGRect(
                    x: currentRect.origin.x + rowWidth,
                    y: currentRect.origin.y,
                    width: currentRect.width - rowWidth,
                    height: currentRect.height
                )
            } else {
                let rowHeight = currentRect.height * CGFloat(rowRatio)
                rowRect = CGRect(
                    x: currentRect.origin.x,
                    y: currentRect.origin.y,
                    width: currentRect.width,
                    height: rowHeight
                )
                currentRect = CGRect(
                    x: currentRect.origin.x,
                    y: currentRect.origin.y + rowHeight,
                    width: currentRect.width,
                    height: currentRect.height - rowHeight
                )
            }

            layoutSlice(
                nodes: row,
                rowSize: rowSize,
                in: rowRect,
                isHorizontal: !isHorizontal,
                minWidth: minWidth,
                minHeight: minHeight
            )

            remaining = rest
            remainingTotal -= rowSize
        }
    }

    private static func splitRow(
        _ nodes: [FileNode],
        for rect: CGRect,
        isHorizontal: Bool
    ) -> (row: [FileNode], rest: [FileNode]) {
        guard !nodes.isEmpty else { return ([], []) }

        var row: [FileNode] = []
        var rowSize: Int64 = 0
        let totalSize = nodes.reduce(Int64(0)) { $0 + $1.totalSize }

        let dimension = isHorizontal ? rect.width : rect.height

        for node in nodes {
            let currentRow = row + [node]
            let currentRowSize = rowSize + node.totalSize

            let currentRatio = worstAspectRatio(
                nodes: currentRow,
                rowSize: currentRowSize,
                totalSize: totalSize,
                dimension: dimension
            )
            let nextRatio = worstAspectRatio(
                nodes: row,
                rowSize: rowSize,
                totalSize: totalSize,
                dimension: dimension
            )

            if row.isEmpty || currentRatio <= nextRatio {
                row.append(node)
                rowSize = currentRowSize
            } else {
                break
            }
        }

        let rest = Array(nodes.dropFirst(row.count))
        return (row, rest)
    }

    private static func worstAspectRatio(
        nodes: [FileNode],
        rowSize: Int64,
        totalSize: Int64,
        dimension: CGFloat
    ) -> Double {
        guard !nodes.isEmpty, rowSize > 0, totalSize > 0 else { return .infinity }

        let rowArea = Double(dimension) * Double(rowSize) / Double(totalSize)
        var worst: Double = 0

        for node in nodes {
            let nodeArea = Double(node.totalSize) / Double(rowSize)
            let w = rowArea * nodeArea
            let h = Double(dimension) / Double(node.totalSize) * Double(rowSize)

            let ratio = max(w / h, h / w)
            worst = max(worst, ratio)
        }

        return worst
    }

    private static func layoutSlice(
        nodes: [FileNode],
        rowSize: Int64,
        in rect: CGRect,
        isHorizontal: Bool,
        minWidth: CGFloat,
        minHeight: CGFloat
    ) {
        guard !nodes.isEmpty, rowSize > 0 else { return }

        var currentOffset: CGFloat = 0

        for node in nodes {
            let ratio = Double(node.totalSize) / Double(rowSize)

            let nodeRect: CGRect
            if isHorizontal {
                let height = rect.height * CGFloat(ratio)
                nodeRect = CGRect(
                    x: rect.origin.x,
                    y: rect.origin.y + currentOffset,
                    width: rect.width,
                    height: max(height, minHeight)
                )
                currentOffset += max(height, minHeight)
            } else {
                let width = rect.width * CGFloat(ratio)
                nodeRect = CGRect(
                    x: rect.origin.x + currentOffset,
                    y: rect.origin.y,
                    width: max(width, minWidth),
                    height: rect.height
                )
                currentOffset += max(width, minWidth)
            }

            node.layoutRect = nodeRect

            if node.isDirectory && !node.children.isEmpty {
                let childRect = nodeRect.insetBy(dx: 1, dy: 1)
                let sorted = node.sortedChildren(by: .sizeDesc)
                squarify(
                    nodes: sorted,
                    totalSize: node.totalSize,
                    into: childRect,
                    minWidth: minWidth,
                    minHeight: minHeight
                )
            }
        }
    }
}
