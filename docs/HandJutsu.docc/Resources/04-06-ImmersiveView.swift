import RealityKit
import SwiftUI

struct ImmersiveView: View {
    @Bindable var handTracking: HandTrackingService
    @State private var visualizer = HandJointVisualizer()

    var body: some View {
        RealityView { content in
            content.add(visualizer.rootEntity)
        } update: { _ in
            visualizer.apply(handTracking.snapshot)
        }
        .task {
            await handTracking.start()
        }
    }
}
