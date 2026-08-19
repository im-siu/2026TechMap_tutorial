import RealityKit
import SwiftUI

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    @State private var visualizer = HandJointVisualizer()

    var body: some View {
        RealityView { content, attachments in
            content.add(visualizer.rootEntity)

            if let hud = attachments.entity(for: "verificationHUD") {
                hud.position = [0, 1.35, -1.0]
                content.add(hud)
            }

            appModel.handTracking.onSnapshotChanged = { snapshot in
                visualizer.apply(snapshot)
            }
            appModel.handTracking.start()
        } attachments: {
            Attachment(id: "verificationHUD") {
                VerificationHUD()
            }
        }
        .onDisappear {
            appModel.handTracking.onSnapshotChanged = nil
        }
    }
}

private struct VerificationHUD: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        let service = appModel.handTracking

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(service.recordingState.isRecording ? .red : .secondary)
                    .frame(width: 12, height: 12)
                Text(service.recordingState.isRecording ? "REC" : "READY")
                    .font(.headline.bold())
                if service.recordingState.isRecording {
                    TimelineView(.periodic(from: .now, by: 0.1)) { context in
                        Text(elapsed(service.recordingElapsed(at: context.date)))
                            .font(.headline.monospacedDigit())
                    }
                }
            }

            Text(service.recordingSessionID ?? "기록을 시작하세요")
                .font(.caption.monospaced())

            if let marker = service.currentMarker {
                Text("#\(marker.index)  \(marker.label)")
                    .font(.title.bold())
                    .foregroundStyle(.yellow)
            } else {
                Text("마커 대기")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Text("L \(service.metrics.left.jointCount)/27 · R \(service.metrics.right.jointCount)/27 · \(service.recordedAnchorUpdateCount) updates")
                .font(.caption.monospacedDigit())
            Text("Feature L:\(featureStatus(service.poseFeatures.left)) R:\(featureStatus(service.poseFeatures.right)) B:\(service.poseFeatures.bimanual.isSuccess ? "OK" : "ERR")")
                .font(.caption.monospaced())
        }
        .padding(18)
        .frame(width: 430, alignment: .leading)
        .glassBackgroundEffect()
    }

    private func featureStatus(_ feature: HandFeatureDebugSnapshot) -> String {
        feature.isSuccess ? "OK" : "ERR(\(feature.sampleJointCount)/25)"
    }

    private func elapsed(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainder = seconds - Double(minutes * 60)
        return String(format: "%02d:%04.1f", minutes, remainder)
    }
}
