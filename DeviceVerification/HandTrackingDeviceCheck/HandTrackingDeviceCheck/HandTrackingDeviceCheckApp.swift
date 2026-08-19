import SwiftUI

@main
struct HandTrackingDeviceCheckApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(appModel)
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                    appModel.handTracking.stop()
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
