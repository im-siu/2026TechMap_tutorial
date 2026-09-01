import SwiftUI

@main
struct HandJutsuApp: App {
    @State private var handTracking = HandTrackingService()

    var body: some Scene {
        WindowGroup {
            ContentView(handTracking: handTracking)
        }

        ImmersiveSpace(id: AppSpace.handJutsu) {
            ImmersiveView(handTracking: handTracking)
        }
    }
}
