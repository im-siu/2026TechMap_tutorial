import ARKit
import RealityKit
import UIKit

@MainActor
final class HandJointVisualizer {
    let rootEntity = Entity()

    private var jointEntities: [HandSide: [HandSkeleton.JointName: ModelEntity]] = [:]

    init() {
        rootEntity.name = "HandJointVisualizerRoot"
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

    private func apply(hand: HandTrackingSnapshot.HandState, side: HandSide) {
        guard hand.isTracked else {
            return
        }

        for joint in hand.joints {
            guard let entity = jointEntities[side]?[joint.name] else {
                continue
            }

            entity.setTransformMatrix(joint.originFromJointTransform, relativeTo: nil)
            entity.isEnabled = true
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
