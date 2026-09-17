import Foundation
import SwiftUI

final class FileScannerViewModel: ObservableObject {
    @Published var rootNode: FileNode?
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var filesScanned = 0
    @Published var selectedNode: FileNode?
    @Published var scanResult: ScanResult?
    @Published var navigationPath: [FileNode] = []
    @Published var colorMapping: ColorMapping = .fileSize
    @Published var colorPalette: ColorPalette = .vivid
    @Published var sortOption: SortOption = .sizeDesc
    @Published var filterMinSize: Int64 = 0
    @Published var filterMaxSize: Int64 = Int64.max
    @Published var filterExtensions: Set<String> = []
    @Published var showHiddenFiles = false
    @Published var showPackages = true

    private let scanner = DiskScanner()
    private var refreshTimer: Timer?

    var colorMapper: FileColorMapper { FileColorMapper(mapping: colorMapping, palette: colorPalette) }
    var colorContext: ColorContext {
        guard let root = activeRoot else { return ColorContext(maxSize: 1, maxDepth: 1, earliestDate: Date(), latestDate: Date()) }
        return buildColorContext(for: root)
    }
    var activeRoot: FileNode? { rootNode }
    var currentDisplayNodes: [FileNode] {
        guard let root = activeRoot else { return [] }
        if let sel = selectedNode, sel.isDirectory { return sel.children }
        return [root]
    }
    var totalSizeFormatted: String {
        guard let root = activeRoot else { return "0 B" }
        return ByteCountFormatter.string(fromByteCount: root.totalSize, countStyle: .file)
    }

    init() {
        scanner.onProgress = { [weak self] count in
            self?.filesScanned = count
            self?.scanProgress = min(Double(count) / 2000.0, 0.99)
        }
        scanner.onComplete = { [weak self] root, result in
            self?.rootNode = root
            self?.scanResult = result
            self?.isScanning = false
            self?.scanProgress = 1.0
            self?.filesScanned = result.fileCount + result.folderCount
            self?.selectedNode = root
            self?.refreshTimer?.invalidate()
            self?.refreshTimer = nil
        }
    }

    func scanFolder() {
        guard let urls = ExportService.showOpenPanel(title: "Select folder"), let url = urls.first else { return }
        startScan(url: url)
    }

    func startScan(url: URL) {
        isScanning = true
        scanProgress = 0
        filesScanned = 0
        selectedNode = nil
        navigationPath = []
        scanner.scan(url: url)

        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    func rescan() {
        guard let root = rootNode else { return }
        startScan(url: URL(fileURLWithPath: root.path))
    }

    func cancelScan() {
        scanner.cancel()
        isScanning = false
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func selectNode(_ node: FileNode?) { selectedNode = node }

    func navigateInto(_ node: FileNode) {
        guard node.isDirectory else { return }
        navigationPath.append(node)
        selectedNode = node
    }

    func navigateUp() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
        selectedNode = navigationPath.last ?? rootNode
    }

    func navigateToRoot() {
        navigationPath = []
        selectedNode = rootNode
    }

    func navigateToIndex(_ i: Int) {
        guard i >= 0, i < navigationPath.count else { navigateToRoot(); return }
        navigationPath = Array(navigationPath.prefix(i + 1))
        selectedNode = navigationPath.last
    }

    func applyFilters() {
        guard let root = activeRoot else { return }
        applyFilterToNode(root)
    }

    private func applyFilterToNode(_ node: FileNode) {
        node.isVisible = node.totalSize >= filterMinSize && node.totalSize <= filterMaxSize &&
            (filterExtensions.isEmpty || filterExtensions.contains(node.fileExtension.lowercased())) &&
            (showHiddenFiles || !node.isHidden)
        node.isFiltered = !(node.totalSize >= filterMinSize && node.totalSize <= filterMaxSize)
        node.children.forEach(applyFilterToNode)
    }

    func exportAsText() {
        guard let root = rootNode else { return }
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd_HHmm"
        guard let url = ExportService.showSavePanel(title: "Export", allowedFileTypes: ["txt"], defaultName: "DiskVision_\(fmt.string(from: Date())).txt") else { return }
        _ = ExportService.exportAsText(rootNode: root, to: url.path)
    }

    func exportAsImage() {
        guard let root = rootNode else { return }
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd_HHmm"
        guard let url = ExportService.showSavePanel(title: "Export", allowedFileTypes: ["png"], defaultName: "DiskVision_\(fmt.string(from: Date())).png") else { return }
        let size = NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
        _ = ExportService.exportAsImage(nodes: [root], size: size, colorMapper: colorMapper, colorContext: buildColorContext(for: root), to: url.path)
    }

    func buildColorContext(for node: FileNode) -> ColorContext {
        var maxSize: Int64 = 0; var maxDepth = 0; var earliest = Date.distantFuture; var latest = Date.distantPast
        func walk(_ n: FileNode) { maxSize = max(maxSize, n.totalSize); maxDepth = max(maxDepth, n.depth); earliest = min(earliest, n.modificationDate); latest = max(latest, n.modificationDate); n.children.forEach(walk) }
        walk(node)
        return ColorContext(maxSize: maxSize, maxDepth: maxDepth, earliestDate: earliest, latestDate: latest)
    }
}
