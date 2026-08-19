import ARKit
import Foundation
import PoseFeatures
import simd

nonisolated struct FingerFeatureDebugSnapshot: Codable, Equatable, Sendable {
    let straightness: Float
    let bendAnglesRadians: [Float]
    let tipToWristDistanceMeters: Float
    let normalizedTipToWristDistance: Float
}

nonisolated struct HandFeatureDebugSnapshot: Codable, Equatable, Sendable {
    let side: String
    let sampleJointCount: Int
    let errorCode: String?
    let missingJoints: [String]
    let palmCenterMeters: SIMD3<Float>?
    let palmNormal: SIMD3<Float>?
    let palmWidthMeters: Float?
    let palmLengthMeters: Float?
    let geometricMeanMeters: Float?
    let fingers: [String: FingerFeatureDebugSnapshot]
    let thumbIndexTipDistanceMeters: Float?
    let normalizedThumbIndexTipDistance: Float?

    var isSuccess: Bool {
        errorCode == nil
    }
}

nonisolated struct BimanualFeatureDebugSnapshot: Codable, Equatable, Sendable {
    let errorCode: String?
    let palmCenterDistanceMeters: Float?
    let normalizedPalmCenterDistance: Float?
    let leftToRightDirection: SIMD3<Float>?
    let palmNormalAlignment: Float?
    let leftPalmFacingRight: Float?
    let rightPalmFacingLeft: Float?
    let mutualFacingScore: Float?
    let timestampSkewSeconds: TimeInterval?

    var isSuccess: Bool {
        errorCode == nil
    }
}

nonisolated struct PoseFeatureEvaluationSnapshot: Codable, Equatable, Sendable {
    let left: HandFeatureDebugSnapshot
    let right: HandFeatureDebugSnapshot
    let bimanual: BimanualFeatureDebugSnapshot
}

enum PoseFeatureAdapter {
    static func evaluate(
        snapshot: HandTrackingSnapshot,
        leftTimestamp: TimeInterval?,
        rightTimestamp: TimeInterval?
    ) -> PoseFeatureEvaluationSnapshot {
        let leftResult = evaluate(hand: snapshot.left, side: .left)
        let rightResult = evaluate(hand: snapshot.right, side: .right)

        let skew: TimeInterval?
        if let leftTimestamp, let rightTimestamp {
            skew = abs(leftTimestamp - rightTimestamp)
        } else {
            skew = nil
        }

        let bimanual: BimanualFeatureDebugSnapshot
        if let leftSample = leftResult.sample, let rightSample = rightResult.sample {
            do {
                let features = try BimanualFeatureExtractor.extract(
                    left: leftSample,
                    right: rightSample
                )
                bimanual = BimanualFeatureDebugSnapshot(
                    errorCode: nil,
                    palmCenterDistanceMeters: features.palmCenterDistance,
                    normalizedPalmCenterDistance: features.normalizedPalmCenterDistance,
                    leftToRightDirection: features.leftToRightDirection,
                    palmNormalAlignment: features.palmNormalAlignment,
                    leftPalmFacingRight: features.leftPalmFacingRight,
                    rightPalmFacingLeft: features.rightPalmFacingLeft,
                    mutualFacingScore: features.mutualFacingScore,
                    timestampSkewSeconds: skew
                )
            } catch {
                bimanual = failedBimanual(error: error, skew: skew)
            }
        } else {
            bimanual = BimanualFeatureDebugSnapshot(
                errorCode: "requiresBothCompleteHands",
                palmCenterDistanceMeters: nil,
                normalizedPalmCenterDistance: nil,
                leftToRightDirection: nil,
                palmNormalAlignment: nil,
                leftPalmFacingRight: nil,
                rightPalmFacingLeft: nil,
                mutualFacingScore: nil,
                timestampSkewSeconds: skew
            )
        }

        return PoseFeatureEvaluationSnapshot(
            left: leftResult.debug,
            right: rightResult.debug,
            bimanual: bimanual
        )
    }

    private static func evaluate(
        hand: HandSnapshot?,
        side: HandSide
    ) -> (sample: PoseFeatures.HandSample?, debug: HandFeatureDebugSnapshot) {
        guard let hand else {
            return (nil, failedHand(side: side, jointCount: 0, error: "anchorNotReceived"))
        }

        let worldPositions = hand.joints.compactMap { sample -> HandJointWorldPosition? in
            guard sample.isTracked, let joint = jointMap[sample.name] else { return nil }
            return HandJointWorldPosition(joint: joint, position: sample.worldPosition)
        }

        do {
            let featureSide: PoseFeatures.HandSide = side == .left ? .left : .right
            let sample = try PoseFeatures.HandSample(
                side: featureSide,
                isTracked: hand.isTracked,
                jointWorldPositions: worldPositions
            )
            do {
                let features = try HandFeatureExtractor.extract(from: sample)
                return (sample, debug(features: features, jointCount: worldPositions.count))
            } catch {
                return (
                    sample,
                    failedHand(
                        side: side,
                        jointCount: worldPositions.count,
                        error: errorDescription(error)
                    )
                )
            }
        } catch {
            return (
                nil,
                failedHand(
                    side: side,
                    jointCount: worldPositions.count,
                    error: errorDescription(error)
                )
            )
        }
    }

    private static func debug(
        features: HandFeatures,
        jointCount: Int
    ) -> HandFeatureDebugSnapshot {
        var fingers: [String: FingerFeatureDebugSnapshot] = [:]
        for (finger, feature) in features.fingers {
            fingers[fingerName(finger)] = FingerFeatureDebugSnapshot(
                straightness: feature.straightness,
                bendAnglesRadians: feature.bendAnglesRadians,
                tipToWristDistanceMeters: feature.tipToWristDistance,
                normalizedTipToWristDistance: feature.normalizedTipToWristDistance
            )
        }

        return HandFeatureDebugSnapshot(
            side: features.side == .left ? "left" : "right",
            sampleJointCount: jointCount,
            errorCode: nil,
            missingJoints: [],
            palmCenterMeters: features.palmCenter,
            palmNormal: features.palmNormal,
            palmWidthMeters: features.normalization.palmWidth,
            palmLengthMeters: features.normalization.palmLength,
            geometricMeanMeters: features.normalization.geometricMean,
            fingers: fingers,
            thumbIndexTipDistanceMeters: features.thumbIndexTipDistance,
            normalizedThumbIndexTipDistance: features.normalizedThumbIndexTipDistance
        )
    }

    private static func failedHand(
        side: HandSide,
        jointCount: Int,
        error: String
    ) -> HandFeatureDebugSnapshot {
        HandFeatureDebugSnapshot(
            side: side == .left ? "left" : "right",
            sampleJointCount: jointCount,
            errorCode: error,
            missingJoints: missingJoints(from: error),
            palmCenterMeters: nil,
            palmNormal: nil,
            palmWidthMeters: nil,
            palmLengthMeters: nil,
            geometricMeanMeters: nil,
            fingers: [:],
            thumbIndexTipDistanceMeters: nil,
            normalizedThumbIndexTipDistance: nil
        )
    }

    private static func failedBimanual(
        error: Error,
        skew: TimeInterval?
    ) -> BimanualFeatureDebugSnapshot {
        BimanualFeatureDebugSnapshot(
            errorCode: errorDescription(error),
            palmCenterDistanceMeters: nil,
            normalizedPalmCenterDistance: nil,
            leftToRightDirection: nil,
            palmNormalAlignment: nil,
            leftPalmFacingRight: nil,
            rightPalmFacingLeft: nil,
            mutualFacingScore: nil,
            timestampSkewSeconds: skew
        )
    }

    private static func errorDescription(_ error: Error) -> String {
        if let error = error as? HandSampleConstructionError {
            switch error {
            case .handNotTracked(let side):
                return "handNotTracked:\(side == .left ? "left" : "right")"
            case .duplicateJoint(let joint):
                return "duplicateJoint:\(joint.rawValue)"
            }
        }

        if let error = error as? FeatureExtractionError {
            switch error {
            case .missingJoints(let joints):
                return "missingJoints:\(joints.map(\.rawValue).joined(separator: ";"))"
            case .nonFinitePosition(let joint):
                return "nonFinitePosition:\(joint.rawValue)"
            case .degeneratePalmScale:
                return "degeneratePalmScale"
            case .degeneratePalmPlane:
                return "degeneratePalmPlane"
            case .degenerateFingerSegment(let finger, let segmentIndex):
                return "degenerateFingerSegment:\(fingerName(finger)):\(segmentIndex)"
            }
        }

        return "unexpected:\(String(describing: error))"
    }

    private static func missingJoints(from error: String) -> [String] {
        guard error.hasPrefix("missingJoints:") else { return [] }
        return String(error.dropFirst("missingJoints:".count)).split(separator: ";").map(String.init)
    }

    private static func fingerName(_ finger: Finger) -> String {
        switch finger {
        case .thumb: "thumb"
        case .index: "index"
        case .middle: "middle"
        case .ring: "ring"
        case .little: "little"
        }
    }

    private static let jointMap: [HandSkeleton.JointName: PoseFeatures.HandJoint] = [
        .wrist: .wrist,
        .thumbKnuckle: .thumbKnuckle,
        .thumbIntermediateBase: .thumbIntermediateBase,
        .thumbIntermediateTip: .thumbIntermediateTip,
        .thumbTip: .thumbTip,
        .indexFingerMetacarpal: .indexFingerMetacarpal,
        .indexFingerKnuckle: .indexFingerKnuckle,
        .indexFingerIntermediateBase: .indexFingerIntermediateBase,
        .indexFingerIntermediateTip: .indexFingerIntermediateTip,
        .indexFingerTip: .indexFingerTip,
        .middleFingerMetacarpal: .middleFingerMetacarpal,
        .middleFingerKnuckle: .middleFingerKnuckle,
        .middleFingerIntermediateBase: .middleFingerIntermediateBase,
        .middleFingerIntermediateTip: .middleFingerIntermediateTip,
        .middleFingerTip: .middleFingerTip,
        .ringFingerMetacarpal: .ringFingerMetacarpal,
        .ringFingerKnuckle: .ringFingerKnuckle,
        .ringFingerIntermediateBase: .ringFingerIntermediateBase,
        .ringFingerIntermediateTip: .ringFingerIntermediateTip,
        .ringFingerTip: .ringFingerTip,
        .littleFingerMetacarpal: .littleFingerMetacarpal,
        .littleFingerKnuckle: .littleFingerKnuckle,
        .littleFingerIntermediateBase: .littleFingerIntermediateBase,
        .littleFingerIntermediateTip: .littleFingerIntermediateTip,
        .littleFingerTip: .littleFingerTip
    ]
}
