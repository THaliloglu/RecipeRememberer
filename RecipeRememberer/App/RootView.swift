import SwiftUI

struct RootView: View {
    @State private var selectedTab: RootTab = UITestLaunchConfiguration.shouldOpenLibraryOnLaunch ? .library : .scanner

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Scanner", systemImage: "viewfinder.circle", value: RootTab.scanner) {
                NavigationStack {
                    ScannerDashboardView()
                }
            }

            Tab("Library", systemImage: "square.stack.3d.down.forward", value: RootTab.library) {
                NavigationStack {
                    LibraryView()
                }
            }
        }
    }
}

private enum RootTab {
    case scanner
    case library
}

#Preview {
    RootView()
        .environment(AppModel())
}
