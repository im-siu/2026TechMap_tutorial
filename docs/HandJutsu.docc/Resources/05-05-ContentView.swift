import SwiftUI

struct ContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @Bindable var handTracking: HandTrackingService
    @State private var immersiveSpaceIsOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(immersiveSpaceIsOpen ? "Close Immersive Space" : "Open Immersive Space") {
                Task {
                    if immersiveSpaceIsOpen {
                        await dismissImmersiveSpace()
                        immersiveSpaceIsOpen = false
                    } else {
                        let result = await openImmersiveSpace(id: AppSpace.immersive.id)
                        immersiveSpaceIsOpen = result == .opened
                    }
                }
            }

            Text(handTracking.statusMessage)

            PoseFeatureSummaryView(
                title: "Left Hand",
                feature: handTracking.snapshot.leftPoseFeature
            )

            PoseFeatureSummaryView(
                title: "Right Hand",
                feature: handTracking.snapshot.rightPoseFeature
            )
        }
        .padding()
    }
}

private struct PoseFeatureSummaryView: View {
    let title: String
    let feature: HandPoseFeature

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            Text(feature.isComplete ? "Pose feature is complete." : "Waiting for required joints.")
            Text("Tracked joints: \(feature.trackedJointCount)")
            Text("Missing joints: \(feature.missingJoints.count)")

            if let distance = feature.thumbTipToIndexTipDistance {
                Text("Thumb to index tip: \(distance, format: .number.precision(.fractionLength(3))) m")
            } else {
                Text("Thumb to index tip: -")
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
