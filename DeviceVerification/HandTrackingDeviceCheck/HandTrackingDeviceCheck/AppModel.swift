import Observation

@MainActor
@Observable
final class AppModel {
    let immersiveSpaceID = "HandTrackingDeviceCheckSpace"
    let handTracking = HandTrackingService()

    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }

    var immersiveSpaceState: ImmersiveSpaceState = .closed
    var immersiveSpaceError: String?
}
