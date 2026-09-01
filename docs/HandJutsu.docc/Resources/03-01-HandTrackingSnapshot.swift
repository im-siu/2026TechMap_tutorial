import ARKit

struct HandTrackingSnapshot {
    var left = HandState()
    var right = HandState()

    struct HandState {
        var isTracked = false
        var hasSkeleton = false
    }

    mutating func update(with anchor: HandAnchor) {
        let state = HandState(
            isTracked: anchor.isTracked,
            hasSkeleton: anchor.handSkeleton != nil
        )

        switch anchor.chirality {
        case .left:
            left = state
        case .right:
            right = state
        }
    }
}
