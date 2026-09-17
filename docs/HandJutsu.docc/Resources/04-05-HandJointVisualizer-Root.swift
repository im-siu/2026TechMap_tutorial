import ARKit
import RealityKit
import UIKit

@MainActor
final class HandJointVisualizer {
    let rootEntity = Entity()

    private var jointEntities: [HandSide: [HandSkeleton.JointName: ModelEntity]] = [:]

    init() {
        rootEntity.name = "HandJointVisualizerRoot"
    }
}
