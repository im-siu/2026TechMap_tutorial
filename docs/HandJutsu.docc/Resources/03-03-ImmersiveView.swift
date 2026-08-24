import RealityKit
import SwiftUI

struct ImmersiveView: View {
    @Bindable var handTracking: HandTrackingService

    var body: some View {
        RealityView { content in
            let root = Entity()
            root.name = "HandJutsuRoot"
            content.add(root)
        }
        .task {
            await handTracking.start()
        }
    }
}
