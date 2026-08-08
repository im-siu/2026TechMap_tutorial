import Foundation

enum HandTrackingStatus: Equatable {
    case idle
    case unsupported
    case starting
    case running
    case stopped
    case failed(String)

    var title: String {
        switch self {
        case .idle:
            "Hand tracking idle"
        case .unsupported:
            "Hand tracking unsupported"
        case .starting:
            "Starting hand tracking"
        case .running:
            "Hand tracking running"
        case .stopped:
            "Hand tracking stopped"
        case .failed:
            "Hand tracking failed"
        }
    }

    var message: String {
        switch self {
        case .idle:
            "Open the immersive space to start the spike."
        case .unsupported:
            "This device or runtime does not support ARKit hand tracking."
        case .starting:
            "Requesting hand-tracking access and starting ARKit."
        case .running:
            "Move both hands in view to inspect tracked joints."
        case .stopped:
            "Close and reopen the immersive space to restart tracking."
        case .failed(let reason):
            reason
        }
    }
}
