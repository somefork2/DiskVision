import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "opticaldisc.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("DiskVision")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("A modern disk usage visualizer for macOS")
                .font(.body)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                featureRow(icon: "map.fill", text: "Interactive treemap visualization")
                featureRow(icon: "paintbrush.fill", text: "Multiple color mapping schemes")
                featureRow(icon: "magnifyingglass", text: "Search and filter files")
                featureRow(icon: "arrow.up.right.square", text: "Reveal in Finder & Quick Look")
                featureRow(icon: "photo", text: "Export as image or text")
                featureRow(icon: "bolt.fill", text: "Fast scanning with progress")
            }
            .padding()

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(32)
        .frame(width: 400)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.caption)
        }
    }
}
