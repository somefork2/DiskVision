import SwiftUI

struct WelcomeWindow: View {
    @EnvironmentObject var viewModel: FileScannerViewModel
    @State private var showAbout = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "opticaldisc.fill").font(.system(size: 72)).foregroundStyle(LinearGradient(colors: [.blue, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("DiskVision").font(.system(size: 42, weight: .bold, design: .rounded))
                Text("Modern Disk Usage Visualizer").font(.title3).foregroundColor(.secondary)
            }
            VStack(spacing: 16) {
                Text("Visualize your disk usage with beautiful treemap visualizations.").multilineTextAlignment(.center).foregroundColor(.secondary).frame(maxWidth: 400)
                Button(action: { viewModel.scanFolder() }) {
                    HStack { Image(systemName: "folder.badge.plus"); Text("Scan Folder") }
                        .font(.headline).frame(width: 200, height: 44)
                }.buttonStyle(.borderedProminent).controlSize(.large)
            }
            Spacer()
            HStack(spacing: 20) {
                Button(action: { showAbout = true }) { Text("About").font(.caption).foregroundColor(.secondary) }.buttonStyle(.plain)
                Text("v1.0.0").font(.caption).foregroundColor(.secondary)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(nsColor: .windowBackgroundColor)).sheet(isPresented: $showAbout) { AboutView() }
    }
}
