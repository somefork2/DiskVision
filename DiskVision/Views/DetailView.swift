import SwiftUI

struct DetailView: View {
    @EnvironmentObject var viewModel: FileScannerViewModel

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            if let node = viewModel.selectedNode {
                selectedNodeInfo(node)
            } else {
                noSelectionInfo
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func selectedNodeInfo(_ node: FileNode) -> some View {
        HStack(spacing: 20) {
            // Icon & Name
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: node.isDirectory ? "folder.fill" : fileIcon(for: node.fileExtension))
                        .font(.title2)
                        .foregroundColor(.accentColor)

                    Text(node.name)
                        .font(.headline)
                        .lineLimit(1)
                }

                Text(node.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Divider().frame(height: 40)

            // Size info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Size:")
                        .foregroundColor(.secondary)
                    Text(ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file))
                        .fontWeight(.semibold)
                }

                if node.isDirectory {
                    HStack {
                        Text("Contents:")
                            .foregroundColor(.secondary)
                        Text("\(node.children.count) items")
                    }
                }
            }
            .font(.caption)

            Divider().frame(height: 40)

            // Dates
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Modified:")
                        .foregroundColor(.secondary)
                    Text(node.modificationDate.formatted(date: .abbreviated, time: .shortened))
                }

                HStack {
                    Text("Created:")
                        .foregroundColor(.secondary)
                    Text(node.creationDate.formatted(date: .abbreviated, time: .shortened))
                }
            }
            .font(.caption)

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button(action: { FileActions.openFile(path: node.path) }) {
                    Label("Open", systemImage: "arrow.up.right.square")
                }

                Button(action: { FileActions.revealInFinder(path: node.path) }) {
                    Label("Finder", systemImage: "folder")
                }

                Button(action: { FileActions.quickLook(path: node.path) }) {
                    Label("Quick Look", systemImage: "eye")
                }

                if node.isDirectory {
                    Button(action: { viewModel.navigateInto(node) }) {
                        Label("Drill Down", systemImage: "arrow.down.right.and.arrow.up.left")
                    }
                }
            }
            .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var noSelectionInfo: some View {
        HStack {
            Spacer()
            Text("Select a file or folder to see details")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private func fileIcon(for ext: String) -> String {
        switch ext.lowercased() {
        case "pdf": return "doc.richtext"
        case "jpg", "jpeg", "png", "gif", "heic", "webp": return "photo"
        case "mp4", "mov", "avi", "mkv": return "video"
        case "mp3", "wav", "flac", "aac": return "music.note"
        case "zip", "tar", "gz", "dmg": return "archivebox"
        case "swift", "js", "ts", "py", "rb": return "chevron.left.forwardslash.chevron.right"
        case "app", "bundle": return "app"
        default: return "doc"
        }
    }
}
