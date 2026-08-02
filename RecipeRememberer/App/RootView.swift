import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var appModel

    @State private var selectedTab: RootTab = UITestLaunchConfiguration.shouldOpenLibraryOnLaunch ? .library : .scanner
    @State private var presentedFeedback: AppModel.RecognitionFeedback?

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
        .onChange(of: appModel.latestFeedback) { _, newFeedback in
            presentedFeedback = newFeedback
        }
        .alert(
            presentedFeedback?.title ?? "",
            isPresented: Binding(
                get: { presentedFeedback != nil },
                set: { isPresented in
                    guard !isPresented else {
                        return
                    }

                    if let presentedFeedback {
                        appModel.dismissLatestFeedback(presentedFeedback)
                    } else {
                        appModel.dismissLatestFeedback()
                    }

                    presentedFeedback = nil
                }
            ),
            presenting: presentedFeedback
        ) { feedback in
            Button("OK", role: .cancel) {
                appModel.dismissLatestFeedback(feedback)
                presentedFeedback = nil
            }
        } message: { feedback in
            Text(feedback.message)
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
