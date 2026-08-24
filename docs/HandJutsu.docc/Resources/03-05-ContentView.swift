import SwiftUI

struct ContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @Bindable var handTracking: HandTrackingService

    @State private var isImmersiveSpaceOpen = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Hand Jutsu")
                .font(.largeTitle)

            VStack(alignment: .leading, spacing: 8) {
                Text(handTracking.statusMessage)
                Text("Left hand: \(label(for: handTracking.snapshot.left))")
                Text("Right hand: \(label(for: handTracking.snapshot.right))")
            }
            .font(.headline)

            Button(isImmersiveSpaceOpen ? "Close Space" : "Open Space") {
                Task {
                    if isImmersiveSpaceOpen {
                        await dismissImmersiveSpace()
                        isImmersiveSpaceOpen = false
                    } else {
                        let result = await openImmersiveSpace(id: AppSpace.handJutsu)

                        if case .opened = result {
                            isImmersiveSpaceOpen = true
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func label(for state: HandTrackingSnapshot.HandState) -> String {
        if state.isTracked && state.hasSkeleton {
            return "tracked"
        }

        if state.isTracked {
            return "tracked, waiting for skeleton"
        }

        return "not tracked"
    }
}
