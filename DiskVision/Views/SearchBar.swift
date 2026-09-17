import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var onSearch: ((String) -> Void)?

    @State private var isEditing = false

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search files...", text: $text, onCommit: {
                onSearch?(text)
            })
            .textFieldStyle(.plain)
            .onTapGesture {
                isEditing = true
            }

            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onSearch?("")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isEditing ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 36 && isEditing { // Enter
                    onSearch?(text)
                }
                if event.keyCode == 53 && isEditing { // Escape
                    isEditing = false
                    text = ""
                }
                return event
            }
        }
    }
}

struct SearchResultRow: View {
    let node: FileNode
    let query: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: node.isDirectory ? "folder.fill" : "doc")
                    .foregroundColor(node.isDirectory ? .accentColor : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(node.name)
                        .font(.system(.body, design: .rounded))
                        .lineLimit(1)

                    Text(node.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Text(ByteCountFormatter.string(fromByteCount: node.totalSize, countStyle: .file))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
