import ARKit
import RealityKit
import UIKit

@MainActor
final class HandJointVisualizer {
    let rootEntity = Entity()

    private var jointEntities: [HandSide: [HandSkeleton.JointName: ModelEntity]] = [:]

    init() {
        rootEntity.name = "Hand Joint Visualizer"
        createJointEntities()
    }

    func apply(_ snapshot: HandTrackingSnapshot) {
        apply(hand: snapshot.left, side: .left)
        apply(hand: snapshot.right, side: .right)
    }

    private func createJointEntities() {
        for side in HandSide.allCases {
            var sideEntities: [HandSkeleton.JointName: ModelEntity] = [:]

            for jointName in HandJointCatalog.all {
                let entity = ModelEntity(
                    mesh: .generateSphere(radius: 0.008),
                    materials: [material(for: side)]
                )
                entity.name = "\(side.title) \(jointName)"
                entity.isEnabled = false
                rootEntity.addChild(entity)
                sideEntities[jointName] = entity
            }

            jointEntities[side] = sideEntities
        }
    }

    private func apply(hand: HandSnapshot?, side: HandSide) {
        guard let hand, hand.isTracked else {
            setJointEntitiesEnabled(false, for: side)
            return
        }

        var visibleJointNames = Set<HandSkeleton.JointName>()

        for joint in hand.joints {
            guard let entity = jointEntities[side]?[joint.name] else { continue }
            entity.setTransformMatrix(joint.originFromJointTransform, relativeTo: nil)
            entity.isEnabled = true
            visibleJointNames.insert(joint.name)
        }

        for (jointName, entity) in jointEntities[side] ?? [:] where !visibleJointNames.contains(jointName) {
            entity.isEnabled = false
        }
    }

    private func setJointEntitiesEnabled(_ isEnabled: Bool, for side: HandSide) {
        guard let entities = jointEntities[side] else { return }

        for entity in entities.values {
            entity.isEnabled = isEnabled
        }
    }

    private func material(for side: HandSide) -> SimpleMaterial {
        let color: UIColor = switch side {
        case .left:
            .systemBlue
        case .right:
            .systemPink
        }

        return SimpleMaterial(color: color, roughness: 0.35, isMetallic: false)
    }
}
