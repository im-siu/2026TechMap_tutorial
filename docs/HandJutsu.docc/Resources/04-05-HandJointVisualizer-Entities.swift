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
