import SwiftUI

@main
struct HandJutsuApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: AppSpace.handJutsu) {
            ImmersiveView()
        }
    }
}
