import SwiftUI

struct FileTreeNode: View {
    let node: FileNode
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isExpanded = false

    private var sizeString: String {
        ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file)
    }

    private var icon: String {
        if node.isDirectory {
            return isExpanded ? "folder.fill" : "folder"
        }
        return fileIcon(for: node.fileExtension)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if node.isDirectory {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                } else {
                    Spacer().frame(width: 12)
                }

                Image(systemName: icon)
                    .foregroundColor(node.isDirectory ? .accentColor : .secondary)
                    .frame(width: 16)

                Text(node.name)
                    .font(.system(.body, design: .rounded))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                Text(sizeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
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
        case "plist", "json", "xml": return "doc.plaintext"
        default: return "doc"
        }
    }
}
