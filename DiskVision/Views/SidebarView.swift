import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var viewModel: FileScannerViewModel
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "opticaldisc.fill")
                        .foregroundColor(.accentColor)
                    Text("DiskVision")
                        .font(.headline)
                    Spacer()
                }

                if let result = viewModel.scanResult {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Total Size:")
                            Spacer()
                            Text(result.formattedTotalSize)
                                .fontWeight(.semibold)
                        }
                        HStack {
                            Text("Files:")
                            Spacer()
                            Text("\(result.fileCount)")
                        }
                        HStack {
                            Text("Folders:")
                            Spacer()
                            Text("\(result.folderCount)")
                        }
                        HStack {
                            Text("Scan Time:")
                            Spacer()
                            Text(result.formattedDuration)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search files...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Color Mapping Controls
            VStack(alignment: .leading, spacing: 8) {
                Text("Color Mapping")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Picker("", selection: $viewModel.colorMapping) {
                    ForEach(ColorMapping.allCases) { mapping in
                        Label(mapping.rawValue, systemImage: mapping.icon)
                            .tag(mapping)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Text("Color Palette")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Picker("", selection: $viewModel.colorPalette) {
                    ForEach(ColorPalette.allCases) { palette in
                        HStack {
                            Circle()
                                .fill(palette.colors.first ?? .gray)
                                .frame(width: 10, height: 10)
                            Text(palette.rawValue)
                        }
                        .tag(palette)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // File Tree
            if let root = viewModel.rootNode {
                List(selection: $viewModel.selectedNode) {
                    Section("Files") {
                        ForEach(root.sortedChildren(by: viewModel.sortOption)) { child in
                            FileTreeNodeRow(node: child)
                                .tag(child)
                        }
                    }
                }
                .listStyle(.sidebar)
            } else {
                Spacer()
            }

            Divider()

            // Sort Controls
            VStack(alignment: .leading, spacing: 8) {
                Text("Sort By")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Picker("", selection: $viewModel.sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct FileTreeNodeRow: View {
    let node: FileNode
    @EnvironmentObject var viewModel: FileScannerViewModel

    var body: some View {
        Button(action: {
            viewModel.selectNode(node)
        }) {
            HStack(spacing: 6) {
                Image(systemName: node.isDirectory ? "folder.fill" : "doc")
                    .foregroundColor(node.isDirectory ? .accentColor : .secondary)
                    .frame(width: 16)

                Text(node.name)
                    .font(.system(.body, design: .rounded))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                Text(ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
