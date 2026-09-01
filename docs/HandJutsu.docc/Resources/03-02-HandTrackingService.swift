import ARKit
import Observation

@Observable
@MainActor
final class HandTrackingService {
    private let session = ARKitSession()
    private let provider = HandTrackingProvider()

    private(set) var snapshot = HandTrackingSnapshot()
    private(set) var statusMessage = "Hand Tracking is not running."

    func start() async {
        guard HandTrackingProvider.isSupported else {
            statusMessage = "Hand Tracking is not supported on this device."
            return
        }

        do {
            try await session.run([provider])
            statusMessage = "Hand Tracking is running."
        } catch {
            statusMessage = "Failed to start Hand Tracking: \(error.localizedDescription)"
        }
    }
}
