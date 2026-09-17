import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var viewModel: FileScannerViewModel

    var body: some View {
        TabView {
            GeneralPreferences()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppearancePreferences()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            AdvancedPreferences()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralPreferences: View {
    @AppStorage("showHiddenFiles") private var showHiddenFiles = false
    @AppStorage("showPackages") private var showPackages = true
    @AppStorage("animateTransitions") private var animateTransitions = true
    @AppStorage("showFileSizeInTooltip") private var showFileSizeInTooltip = true

    var body: some View {
        Form {
            Toggle("Show hidden files by default", isOn: $showHiddenFiles)
            Toggle("Show package contents", isOn: $showPackages)
            Toggle("Animate view transitions", isOn: $animateTransitions)
            Toggle("Show file size in tooltips", isOn: $showFileSizeInTooltip)
        }
        .padding()
    }
}

struct AppearancePreferences: View {
    @EnvironmentObject var viewModel: FileScannerViewModel

    var body: some View {
        Form {
            Picker("Default Color Mapping", selection: $viewModel.colorMapping) {
                ForEach(ColorMapping.allCases) { mapping in
                    Label(mapping.rawValue, systemImage: mapping.icon)
                        .tag(mapping)
                }
            }

            Picker("Default Color Palette", selection: $viewModel.colorPalette) {
                ForEach(ColorPalette.allCases) { palette in
                    HStack {
                        Circle()
                            .fill(palette.colors.first ?? .gray)
                            .frame(width: 12, height: 12)
                        Text(palette.rawValue)
                    }
                    .tag(palette)
                }
            }

            Picker("Default Sort Order", selection: $viewModel.sortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        }
        .padding()
    }
}

struct AdvancedPreferences: View {
    @AppStorage("maxScanDepth") private var maxScanDepth = 20
    @AppStorage("showDottedGrid") private var showDottedGrid = false

    var body: some View {
        Form {
            Stepper("Max scan depth: \(maxScanDepth)", value: $maxScanDepth, in: 5...50)
            Toggle("Show dotted grid background", isOn: $showDottedGrid)
        }
        .padding()
    }
}
