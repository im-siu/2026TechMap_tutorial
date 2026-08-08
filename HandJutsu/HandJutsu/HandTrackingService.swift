import ARKit
import Foundation

@MainActor
@Observable
final class HandTrackingService {
    private let session = ARKitSession()
    private let provider = HandTrackingProvider()
    private var trackingTask: Task<Void, Never>?
    private var latestSnapshot = HandTrackingSnapshot.empty

    var status: HandTrackingStatus = .idle
    var leftHandSummary = "Left: waiting"
    var rightHandSummary = "Right: waiting"
    var onSnapshotChanged: ((HandTrackingSnapshot) -> Void)?

    var isRunning: Bool {
        trackingTask != nil
    }

    func start() {
        guard trackingTask == nil else { return }

        guard HandTrackingProvider.isSupported else {
            status = .unsupported
            onSnapshotChanged?(.empty)
            return
        }

        status = .starting

        trackingTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await session.run([provider])
                status = .running

                for await update in provider.anchorUpdates {
                    guard !Task.isCancelled else { return }
                    handle(anchor: update.anchor)
                }
            } catch {
                status = .failed(error.localizedDescription)
                trackingTask = nil
                onSnapshotChanged?(.empty)
            }
        }
    }

    func stop() {
        trackingTask?.cancel()
        trackingTask = nil
        session.stop()
        status = .stopped
        latestSnapshot = .empty
        leftHandSummary = "Left: stopped"
        rightHandSummary = "Right: stopped"
        onSnapshotChanged?(.empty)
    }

    private func handle(anchor: HandAnchor) {
        guard let side = HandSide(chirality: anchor.chirality) else { return }

        let handSnapshot = makeSnapshot(for: side, anchor: anchor)

        switch side {
        case .left:
            latestSnapshot.left = handSnapshot
            leftHandSummary = summary(for: handSnapshot)
        case .right:
            latestSnapshot.right = handSnapshot
            rightHandSummary = summary(for: handSnapshot)
        }

        onSnapshotChanged?(latestSnapshot)
    }

    private func makeSnapshot(for side: HandSide, anchor: HandAnchor) -> HandSnapshot {
        guard anchor.isTracked, let skeleton = anchor.handSkeleton else {
            return HandSnapshot(side: side, isTracked: false, joints: [])
        }

        let joints = HandJointCatalog.all.compactMap { jointName -> HandJointSample? in
            let joint = skeleton.joint(jointName)
            guard joint.isTracked else { return nil }

            let originFromJointTransform = anchor.originFromAnchorTransform * joint.anchorFromJointTransform
            return HandJointSample(name: jointName, originFromJointTransform: originFromJointTransform)
        }

        return HandSnapshot(side: side, isTracked: true, joints: joints)
    }

    private func summary(for hand: HandSnapshot) -> String {
        guard hand.isTracked else {
            return "\(hand.side.title): tracking lost"
        }

        return "\(hand.side.title): \(hand.joints.count) joints"
    }
}
