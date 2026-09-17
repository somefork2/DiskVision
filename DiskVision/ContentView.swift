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
                        Color(nsColor: .windowBackgroundColor).ignoresSafeArea()

                        if viewModel.isScanning, let root = viewModel.activeRoot {
                            LiveTreemapCanvas(
                                root: root,
                                size: geo.size,
                                version: viewModel.scanVersion
                            )
                            .allowsHitTesting(false)
                            .overlay(alignment: .center) { scanOverlay }

                        } else if let root = viewModel.rootNode {
                            let nodes = viewModel.currentDisplayNodes
                            if !nodes.isEmpty {
                                TreemapView(nodes: nodes, size: geo.size).environmentObject(viewModel)
                            } else {
                                emptyState
                            }
                        } else {
                            WelcomeView()
                        }
                    }
                }

                if viewModel.rootNode != nil { DetailView().frame(height: 140) }
            }
        }
        .toolbar { ToolbarItemGroup(placement: .automatic) { ToolbarButtons() } }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.fill").font(.system(size: 48)).foregroundColor(.secondary)
            Text("No files").font(.title3).foregroundColor(.secondary)
        }
    }

    private var scanOverlay: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "opticaldisc").font(.system(size: 14)).foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    Text("Scanning...").font(.system(.headline, design: .rounded))
                }
                SwiftUI.ProgressView(value: viewModel.scanProgress).progressViewStyle(.linear).frame(width: 260)
                HStack { Text("\(viewModel.filesScanned) items").font(.caption); Spacer(); Text("\(Int(viewModel.scanProgress * 100))%").font(.caption).monospacedDigit() }
                    .foregroundColor(.secondary).frame(width: 260)
            }.padding(14).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            Spacer().frame(height: 60)
        }.padding()
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "opticaldisc.fill").font(.system(size: 64)).foregroundStyle(LinearGradient(colors: [.blue, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("DiskVision").font(.system(size: 36, weight: .bold, design: .rounded))
                Text("Visualize your disk usage").font(.title3).foregroundColor(.secondary)
            }
            Text("Choose a folder to scan and visualize its disk usage as an interactive treemap.").multilineTextAlignment(.center).foregroundColor(.secondary).frame(maxWidth: 400)
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(nsColor: .windowBackgroundColor))
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
