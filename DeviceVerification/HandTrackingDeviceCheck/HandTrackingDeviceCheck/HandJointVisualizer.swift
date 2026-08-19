import ARKit
import RealityKit
import UIKit

@MainActor
final class HandJointVisualizer {
    let rootEntity = Entity()

    private var jointEntities: [HandSide: [HandSkeleton.JointName: ModelEntity]] = [:]

    init() {
        rootEntity.name = "Hand Tracking Device Check"
        createJointEntities()
    }

    func apply(_ snapshot: HandTrackingSnapshot) {
        apply(hand: snapshot.left, side: .left)
        apply(hand: snapshot.right, side: .right)
    }

    private func createJointEntities() {
        for side in HandSide.allCases {
            var entities: [HandSkeleton.JointName: ModelEntity] = [:]

            for jointName in HandJointCatalog.all {
                let entity = ModelEntity(
                    mesh: .generateSphere(radius: 0.007),
                    materials: [material(for: side)]
                )
                entity.name = "\(side.title) \(jointName)"
                entity.isEnabled = false
                rootEntity.addChild(entity)
                entities[jointName] = entity
            }

            jointEntities[side] = entities
        }
    }

    private func apply(hand: HandSnapshot?, side: HandSide) {
        guard let hand, hand.isTracked else {
            setEnabled(false, for: side)
            return
        }

        var visibleJointNames = Set<HandSkeleton.JointName>()
        for joint in hand.joints {
            guard let entity = jointEntities[side]?[joint.name] else { continue }
            guard joint.isTracked else {
                entity.isEnabled = false
                continue
            }
            entity.setTransformMatrix(joint.originFromJointTransform, relativeTo: nil)
            entity.isEnabled = true
            visibleJointNames.insert(joint.name)
        }

        for (jointName, entity) in jointEntities[side] ?? [:]
        where !visibleJointNames.contains(jointName) {
            entity.isEnabled = false
        }
    }

    private func setEnabled(_ isEnabled: Bool, for side: HandSide) {
        for entity in jointEntities[side]?.values ?? [:].values {
            entity.isEnabled = isEnabled
        }
    }

    private func material(for side: HandSide) -> SimpleMaterial {
        let color: UIColor = side == .left ? .systemBlue : .systemPink
        return SimpleMaterial(color: color, roughness: 0.3, isMetallic: false)
    }
}
