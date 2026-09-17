import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: FileScannerViewModel
    @State private var showSidebar = true

    var body: some View {
        HSplitView {
            if showSidebar { SidebarView().frame(minWidth: 220, idealWidth: 260, maxWidth: 350) }

            VStack(spacing: 0) {
                ToolbarView(showSidebar: $showSidebar)

                GeometryReader { geo in
                    ZStack {
                        Color(red: 0.06, green: 0.06, blue: 0.10).ignoresSafeArea()

                        if let root = viewModel.activeRoot {
                            if viewModel.isScanning {
                                TreemapNSViewRepresentable(
                                    root: root,
                                    size: geo.size,
                                    colorMapper: viewModel.colorMapper,
                                    version: viewModel.filesScanned
                                )
                                .overlay(alignment: .bottom) {
                                    scanBar
                                }
                            } else {
                                let nodes = viewModel.currentDisplayNodes
                                if !nodes.isEmpty {
                                    TreemapNSViewRepresentable(
                                        root: root,
                                        size: geo.size,
                                        colorMapper: viewModel.colorMapper,
                                        version: 0
                                    )
                                } else {
                                    emptyView
                                }
                            }
                        } else {
                            WelcomeView()
                        }
                    }
                }

                if viewModel.rootNode != nil { DetailView().frame(height: 130) }
            }
        }
        .toolbar { ToolbarItemGroup(placement: .automatic) { ToolbarButtons() } }
    }

    private var scanBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "opticaldisc").font(.system(size: 13))
            Text("Scanning...").font(.system(.caption, design: .rounded)).fontWeight(.semibold)
            SwiftUI.ProgressView(value: viewModel.scanProgress).progressViewStyle(.linear).frame(width: 160)
            Text("\(viewModel.filesScanned)").font(.system(.caption, design: .rounded).monospacedDigit())
            Spacer()
            Button("Cancel") { viewModel.cancelScan() }.font(.caption).buttonStyle(.bordered)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.fill").font(.system(size: 48)).foregroundColor(.secondary)
            Text("No files").font(.title3).foregroundColor(.secondary)
        }
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "opticaldisc.fill").font(.system(size: 64))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
            Text("DiskVision").font(.system(size: 36, weight: .bold, design: .rounded))
            Text("Visualize your disk usage").font(.title3).foregroundColor(.secondary)
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(red: 0.06, green: 0.06, blue: 0.10))
    }
}

struct ToolbarButtons: View {
    @EnvironmentObject var viewModel: FileScannerViewModel
    var body: some View {
        Group {
            Button(action: { viewModel.scanFolder() }) { Label("Scan Folder", systemImage: "folder.badge.plus") }
            if viewModel.isScanning { Button(action: { viewModel.cancelScan() }) { Label("Cancel", systemImage: "xmark.circle") } }
            else if viewModel.rootNode != nil { Button(action: { viewModel.rescan() }) { Label("Rescan", systemImage: "arrow.clockwise") } }
        }
    }
}
