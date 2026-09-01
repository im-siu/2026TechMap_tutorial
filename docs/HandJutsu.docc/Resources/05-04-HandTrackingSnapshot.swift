import ARKit

struct HandTrackingSnapshot {
    var left = HandState()
    var right = HandState()

    var leftPoseFeature: HandPoseFeature {
        HandPoseFeatureBuilder.makeFeature(for: .left, from: left)
    }

    var rightPoseFeature: HandPoseFeature {
        HandPoseFeatureBuilder.makeFeature(for: .right, from: right)
    }

    struct HandState {
        var isTracked = false
        var hasSkeleton = false
        var joints: [HandJointSample] = []
    }

    mutating func update(with anchor: HandAnchor) {
        let state = HandState(
            isTracked: anchor.isTracked,
            hasSkeleton: anchor.handSkeleton != nil,
            joints: jointSamples(from: anchor)
        )

        switch anchor.chirality {
        case .left:
            left = state
        case .right:
            right = state
        @unknown default:
            return
        }
    }

    private func jointSamples(from anchor: HandAnchor) -> [HandJointSample] {
        guard anchor.isTracked, let skeleton = anchor.handSkeleton else {
            return []
        }

        return HandJointCatalog.all.compactMap { name in
            let joint = skeleton.joint(name)

            guard joint.isTracked else {
                return nil
            }

            return HandJointSample(
                name: name,
                originFromJointTransform: anchor.originFromAnchorTransform * joint.anchorFromJointTransform
            )
        }
    }
}
