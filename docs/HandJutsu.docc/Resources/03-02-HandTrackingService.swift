import ARKit
import Observation

enum HandTrackingStatus {
    case idle
    case unsupported
    case requestingPermission
    case denied
    case running
    case failed(String)

    var message: String {
        switch self {
        case .idle:
            return "Open the Immersive Space to start Hand Tracking."
        case .unsupported:
            return "Hand Tracking is not supported on this device."
        case .requestingPermission:
            return "Waiting for Hand Tracking permission."
        case .denied:
            return "Hand Tracking permission was not allowed."
        case .running:
            return "Hand Tracking is running."
        case .failed(let description):
            return "Failed to start Hand Tracking: \(description)"
        }
    }
}

@Observable
@MainActor
final class HandTrackingService {
    private let session = ARKitSession()
    private let provider = HandTrackingProvider()

    private(set) var snapshot = HandTrackingSnapshot()
    private(set) var status = HandTrackingStatus.idle

    func start() async {
        guard HandTrackingProvider.isSupported else {
            status = .unsupported
            return
        }

        var authorization = await session.queryAuthorization(for: [.handTracking])[.handTracking] ?? .notDetermined

        if authorization == .notDetermined {
            status = .requestingPermission
            authorization = await session.requestAuthorization(for: [.handTracking])[.handTracking] ?? .notDetermined
        }

        guard authorization == .allowed else {
            status = .denied
            return
        }

        do {
            try await session.run([provider])
            status = .running
        } catch {
            if Task.isCancelled {
                return
            }

            status = .failed(error.localizedDescription)
        }
    }

    func stop() {
        session.stop()
        snapshot = HandTrackingSnapshot()
        status = .idle
    }
}
