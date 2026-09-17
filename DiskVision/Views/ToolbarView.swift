import SwiftUI

struct ToolbarView: View {
    @EnvironmentObject var viewModel: FileScannerViewModel
    @Binding var showSidebar: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Navigation breadcrumbs
            if !viewModel.navigationPath.isEmpty {
                HStack(spacing: 4) {
                    Button(action: { viewModel.navigateToRoot() }) {
                        Image(systemName: "house")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)

                    ForEach(Array(viewModel.navigationPath.enumerated()), id: \.element.id) { index, node in
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Button(action: { viewModel.navigateToIndex(index) }) {
                            Text(node.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 8)
            }

            Spacer()

            // Info
            if let root = viewModel.rootNode {
                Text(viewModel.totalSizeFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Actions
            HStack(spacing: 8) {
                if viewModel.selectedNode != nil {
                    Button(action: { FileActions.revealInFinder(path: viewModel.selectedNode!.path) }) {
                        Image(systemName: "arrow.up.right.square")
                    }
                    .buttonStyle(.plain)
                    .help("Reveal in Finder")

                    Button(action: { FileActions.quickLook(path: viewModel.selectedNode!.path) }) {
                        Image(systemName: "eye")
                    }
                    .buttonStyle(.plain)
                    .help("Quick Look")
                }

                Button(action: { viewModel.exportAsImage() }) {
                    Image(systemName: "photo")
                }
                .buttonStyle(.plain)
                .help("Export as Image")

                Button(action: { viewModel.exportAsText() }) {
                    Image(systemName: "doc.text")
                }
                .buttonStyle(.plain)
                .help("Export as Text")
            }

            Divider().frame(height: 20)

            // View toggles
            Button(action: { withAnimation { showSidebar.toggle() } }) {
                Image(systemName: showSidebar ? "sidebar.left" : "sidebar.left")
                    .foregroundColor(showSidebar ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Sidebar")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
