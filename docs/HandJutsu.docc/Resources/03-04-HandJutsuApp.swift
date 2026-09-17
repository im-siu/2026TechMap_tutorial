import SwiftUI

@main
struct HandJutsuApp: App {
    @State private var handTracking = HandTrackingService()
    @State private var immersionStyle: ImmersionStyle = .full

    var body: some Scene {
        WindowGroup {
            ContentView(handTracking: handTracking)
        }

        ImmersiveSpace(id: AppSpace.handJutsu) {
            ImmersiveView(handTracking: handTracking)
        }
        .immersionStyle(selection: $immersionStyle, in: .full)
    }
}
