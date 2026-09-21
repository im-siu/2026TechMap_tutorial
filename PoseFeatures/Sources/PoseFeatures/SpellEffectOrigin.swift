import Foundation

public enum SpellEffectOrigin {
    public static func make(left: HandPoseInput, right: HandPoseInput) -> SIMD3<Float>? {
        guard left.side == .left, right.side == .right,
              let leftIndexTip = left.jointPositions[.indexFingerTip],
              let leftMiddleTip = left.jointPositions[.middleFingerTip],
              let rightIndexTip = right.jointPositions[.indexFingerTip],
              let rightMiddleTip = right.jointPositions[.middleFingerTip] else {
            return nil
        }

        return (leftIndexTip + leftMiddleTip + rightIndexTip + rightMiddleTip) / 4
    }
}
