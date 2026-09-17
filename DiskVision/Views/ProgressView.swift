import SwiftUI

struct ScanningOverlayView: View {
    @EnvironmentObject var viewModel: FileScannerViewModel

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "opticaldisc")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Scanning disk...")
                    .font(.title3)
                    .fontWeight(.medium)

                Text("\(viewModel.filesScanned) files scanned")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                SwiftUI.ProgressView(value: viewModel.scanProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 300)

                Text("\(Int(viewModel.scanProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct ScanProgressView: View {
    @EnvironmentObject var viewModel: FileScannerViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "opticaldisc")
                    .foregroundColor(.accentColor)
                Text("Scanning...")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    viewModel.cancelScan()
                }
                .buttonStyle(.bordered)
            }

            SwiftUI.ProgressView(value: viewModel.scanProgress)
                .progressViewStyle(.linear)

            HStack {
                Text("\(viewModel.filesScanned) files scanned")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(viewModel.scanProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}
