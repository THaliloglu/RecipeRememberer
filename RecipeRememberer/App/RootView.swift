import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Scanner", systemImage: "viewfinder.circle") {
                NavigationStack {
                    ScannerDashboardView()
                }
            }

            Tab("Library", systemImage: "square.stack.3d.down.forward") {
                NavigationStack {
                    LibraryView()
                }
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppModel())
}
