import SwiftUI

struct FilterPanel: View {
    @EnvironmentObject var viewModel: FileScannerViewModel
    @Binding var isPresented: Bool

    @State private var minSizeMB: Double = 0
    @State private var maxSizeMB: Double = 1000
    @State private var extensionFilter = ""
    @State private var showHidden = false
    @State private var showPackages = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .foregroundColor(.accentColor)
                Text("Filters")
                    .font(.headline)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Size filter
            VStack(alignment: .leading, spacing: 8) {
                Text("File Size")
                    .font(.caption)
                    .fontWeight(.semibold)

                HStack {
                    Text("Min:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0", value: $minSizeMB, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("MB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Max:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("1000", value: $maxSizeMB, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("MB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Extension filter
            VStack(alignment: .leading, spacing: 8) {
                Text("File Extension")
                    .font(.caption)
                    .fontWeight(.semibold)

                TextField("e.g. jpg, pdf, mp4", text: $extensionFilter)
                    .textFieldStyle(.roundedBorder)
            }

            Divider()

            // Toggles
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Show hidden files", isOn: $showHidden)
                    .font(.caption)

                Toggle("Show packages", isOn: $showPackages)
                    .font(.caption)
            }

            Divider()

            HStack {
                Button("Apply Filters") {
                    applyFilters()
                }
                .buttonStyle(.borderedProminent)

                Button("Reset") {
                    resetFilters()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 260)
    }

    private func applyFilters() {
        viewModel.filterMinSize = Int64(minSizeMB * 1_000_000)
        viewModel.filterMaxSize = Int64(maxSizeMB * 1_000_000)
        viewModel.filterExtensions = Set(extensionFilter.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces).lowercased()
        })
        viewModel.showHiddenFiles = showHidden
        viewModel.showPackages = showPackages
        viewModel.applyFilters()
    }

    private func resetFilters() {
        minSizeMB = 0
        maxSizeMB = 1000
        extensionFilter = ""
        showHidden = false
        showPackages = true
        viewModel.filterMinSize = 0
        viewModel.filterMaxSize = Int64.max
        viewModel.filterExtensions = []
        viewModel.showHiddenFiles = false
        viewModel.showPackages = true
        viewModel.applyFilters()
    }
}
