import ARKit
import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class HandTrackingService {
    private let session = ARKitSession()
    private let provider = HandTrackingProvider()
    private let recorder = VerificationSessionRecorder()
    private var trackingTask: Task<Void, Never>?
    private var latestSnapshot = HandTrackingSnapshot.empty
    private var latestAnchorTimestamp: [HandSide: TimeInterval] = [:]
    private var workingMetrics = VerificationMetrics()
    private var workingPoseFeatures = PoseFeatureAdapter.evaluate(
        snapshot: .empty,
        leftTimestamp: nil,
        rightTimestamp: nil
    )
    private var lastPublishedAt = Date.distantPast
    private var lastUpdateBySide: [HandSide: Date] = [:]
    private var markerIndex = 0
    private var activeMarkerCaptureInput: MarkerCaptureInput?

    var status: HandTrackingStatus = .idle
    var authorization: HandAuthorizationState = .unknown
    var metrics = VerificationMetrics()
    var displaySnapshot = HandTrackingSnapshot.empty
    var poseFeatures = PoseFeatureAdapter.evaluate(
        snapshot: .empty,
        leftTimestamp: nil,
        rightTimestamp: nil
    )
    var logEntries: [VerificationLogEntry] = []
    var recordingState: VerificationRecordingState = .idle
    var recordingSessionID: String?
    var recordingStartedAt: Date?
    var currentMarker: RecordingMarker?
    var exportURLs: [URL] = []
    var exportFolderURL: URL?
    var recordedAnchorUpdateCount = 0
    var onSnapshotChanged: ((HandTrackingSnapshot) -> Void)?

    var isRunning: Bool {
        trackingTask != nil
    }

    var isSupported: Bool {
        HandTrackingProvider.isSupported
    }

    var hasActiveRecording: Bool {
        recordingState.isRecording || isRecordingFailure
    }

    var canStartRecording: Bool {
        guard status == .running else { return false }
        switch recordingState {
        case .idle, .ready:
            return true
        case .failed:
            return recordingSessionID == nil
        case .starting, .recording, .stopping:
            return false
        }
    }

    var reportText: String {
        let lastUpdate = metrics.lastUpdateAt?.formatted(date: .numeric, time: .standard) ?? "없음"
        return """
        Hand Tracking + Pose Features 실기기 검증
        Issue: #23
        생성 시각: \(Date().formatted(date: .numeric, time: .standard))
        기기: \(UIDevice.current.model) / \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
        지원 여부: \(isSupported ? "지원됨" : "지원하지 않음")
        권한: \(authorization.rawValue)
        세션: \(status.title)
        기록 세션: \(recordingSessionID ?? "없음")
        기록 Anchor update: \(recordedAnchorUpdateCount)
        왼손: \(observationReport(metrics.left))
        오른손: \(observationReport(metrics.right))
        왼손 특징: \(poseFeatures.left.errorCode ?? "success")
        오른손 특징: \(poseFeatures.right.errorCode ?? "success")
        양손 특징: \(poseFeatures.bimanual.errorCode ?? "success")
        손바닥 중심 거리: \(formatCentimeters(metrics.palmCenterDistanceMeters))
        정규화 손바닥 중심 거리: \(formatRatio(metrics.normalizedPalmCenterDistance))
        좌우 timestamp 차이: \(formatMilliseconds(poseFeatures.bimanual.timestampSkewSeconds))
        마지막 수신: \(lastUpdate)
        """
    }

    func recordingElapsed(at date: Date = Date()) -> TimeInterval {
        guard let recordingStartedAt else { return 0 }
        return max(0, date.timeIntervalSince(recordingStartedAt))
    }

    func start() {
        guard trackingTask == nil else { return }
        guard HandTrackingProvider.isSupported else {
            status = .unsupported
            addLog("이 런타임은 HandTrackingProvider를 지원하지 않습니다.")
            onSnapshotChanged?(.empty)
            return
        }

        status = .requestingAuthorization
        addLog("손 추적 권한 확인을 시작했습니다.")
        trackingTask = Task { @MainActor [weak self] in
            await self?.runSession()
        }
    }

    func stop() {
        trackingTask?.cancel()
        trackingTask = nil
        session.stop()
        latestSnapshot = .empty
        displaySnapshot = .empty
        latestAnchorTimestamp.removeAll()
        displaySnapshot = .empty
        clearLiveTrackingValues()
        poseFeatures = PoseFeatureAdapter.evaluate(
            snapshot: .empty,
            leftTimestamp: nil,
            rightTimestamp: nil
        )
        workingPoseFeatures = poseFeatures
        onSnapshotChanged?(.empty)

        if recordingState.isRecording {
            stopRecording()
        }
        if status == .running || status == .starting || status == .requestingAuthorization {
            status = .stopped
            addLog("Hand Tracking 세션을 중지했습니다.")
        }
    }

    func startRecording() {
        guard status == .running else {
            recordingState = .failed("Hand Tracking 세션을 먼저 시작하세요.")
            return
        }
        guard !recordingState.isRecording else { return }

        recordingState = .starting
        recordingSessionID = nil
        recordingStartedAt = nil
        exportURLs = []
        exportFolderURL = nil
        recordedAnchorUpdateCount = 0
        markerIndex = 0
        currentMarker = nil
        activeMarkerCaptureInput = nil

        let startedAt = Date()
        let metadata = makeRecordingMetadata(startedAt: startedAt)
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let recording = try await recorder.start(metadata: metadata)
                recordingSessionID = recording.sessionID
                recordingStartedAt = recording.startedAt
                exportFolderURL = recording.folderURL
                recordingState = .recording
                addLog("검증 기록을 시작했습니다: \(recording.sessionID)")
                addMarker(
                    category: .system,
                    code: "start",
                    label: "START"
                )
            } catch {
                recordingState = .failed(error.localizedDescription)
                addLog("기록 시작 오류: \(error.localizedDescription)")
            }
        }
    }

    func stopRecording() {
        guard recordingState.isRecording || isRecordingFailure else { return }
        recordingState = .stopping

        let context = VerificationRecordingStopContext(
            leftTrackingLossCount: workingMetrics.left.lossCount,
            rightTrackingLossCount: workingMetrics.right.lossCount,
            notes: "Issue #23 device verification"
        )
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                if let export = try await recorder.stop(context: context) {
                    recordingSessionID = export.sessionID
                    exportFolderURL = export.folderURL
                    exportURLs = export.files
                    recordingState = .ready
                    addLog("검증 파일 \(export.files.count)개를 저장했습니다.")
                } else {
                    recordingState = .idle
                }
                recordingStartedAt = nil
                currentMarker = nil
                activeMarkerCaptureInput = nil
            } catch {
                recordingState = .failed(error.localizedDescription)
                addLog("기록 종료 오류: \(error.localizedDescription)")
            }
        }
    }

    func addHandSealMarker(_ seal: NinjutsuHandSeal) {
        addMarker(
            category: .handSeal,
            code: seal.code,
            label: seal.displayName
        )
    }

    func addCustomMarker(_ description: String) {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        addMarker(
            category: .custom,
            code: "custom",
            label: "기타",
            customDescription: trimmed
        )
    }

    private func addMarker(
        category: RecordingMarkerCategory,
        code: String,
        label: String,
        customDescription: String? = nil
    ) {
        guard recordingState.isRecording else { return }
        markerIndex += 1
        let marker = RecordingMarker(
            index: markerIndex,
            category: category,
            code: code,
            label: label,
            customDescription: customDescription,
            elapsedSeconds: recordingElapsed()
        )
        currentMarker = marker

        let captureInput = MarkerCaptureInput(
            wallClock: Date(),
            elapsedSeconds: marker.elapsedSeconds,
            index: marker.index,
            category: marker.category,
            code: marker.code,
            label: marker.label,
            customDescription: marker.customDescription
        )
        activeMarkerCaptureInput = captureInput

        Task { [recorder] in
            try? await recorder.record(
                marker: captureInput
            )
        }
    }

    func resetObservations() {
        guard !recordingState.isRecording else {
            addLog("기록 중에는 관찰값을 초기화하지 않습니다.")
            return
        }
        workingMetrics = VerificationMetrics()
        metrics = workingMetrics
        logEntries.removeAll()
        lastUpdateBySide.removeAll()
        latestAnchorTimestamp.removeAll()
        lastPublishedAt = .distantPast
        recordedAnchorUpdateCount = 0
        poseFeatures = PoseFeatureAdapter.evaluate(
            snapshot: .empty,
            leftTimestamp: nil,
            rightTimestamp: nil
        )
        workingPoseFeatures = poseFeatures
        addLog("관찰값을 초기화했습니다.")
    }

    private var isRecordingFailure: Bool {
        if case .failed = recordingState { return recordingSessionID != nil }
        return false
    }

    private func runSession() async {
        let currentResults = await session.queryAuthorization(for: [.handTracking])
        let currentStatus = currentResults[.handTracking] ?? .notDetermined
        updateAuthorization(currentStatus)

        let finalStatus: ARKitSession.AuthorizationStatus
        if currentStatus == .notDetermined {
            let requestedResults = await session.requestAuthorization(for: [.handTracking])
            finalStatus = requestedResults[.handTracking] ?? .notDetermined
            updateAuthorization(finalStatus)
        } else {
            finalStatus = currentStatus
        }

        guard finalStatus == .allowed else {
            status = .denied
            trackingTask = nil
            addLog("손 추적 권한이 허용되지 않았습니다.")
            return
        }
        guard !Task.isCancelled else {
            trackingTask = nil
            return
        }

        status = .starting
        do {
            try await session.run([provider])
            guard !Task.isCancelled else {
                trackingTask = nil
                return
            }

            status = .running
            addLog("HandTrackingProvider가 실행 중입니다.")
            for await update in provider.anchorUpdates {
                guard !Task.isCancelled else { break }
                switch update.event {
                case .added:
                    await handle(anchor: update.anchor, event: "added", timestamp: update.timestamp)
                case .updated:
                    await handle(anchor: update.anchor, event: "updated", timestamp: update.timestamp)
                case .removed:
                    await handleRemoved(anchor: update.anchor, timestamp: update.timestamp)
                }
            }
        } catch {
            guard !Task.isCancelled else {
                trackingTask = nil
                return
            }
            status = .failed(error.localizedDescription)
            addLog("ARKitSession 오류: \(error.localizedDescription)")
            onSnapshotChanged?(.empty)
        }
        trackingTask = nil
    }

    private func updateAuthorization(_ value: ARKitSession.AuthorizationStatus) {
        switch value {
        case .allowed:
            authorization = .allowed
            addLog("손 추적 권한이 허용되었습니다.")
        case .denied:
            authorization = .denied
            addLog("손 추적 권한이 거부되었습니다.")
        case .notDetermined:
            authorization = .notDetermined
        @unknown default:
            authorization = .unknown
        }
    }

    private func handle(
        anchor: HandAnchor,
        event: String,
        timestamp: TimeInterval
    ) async {
        guard let side = HandSide(chirality: anchor.chirality) else { return }
        let handSnapshot = makeSnapshot(for: side, anchor: anchor)
        latestSnapshot[side] = handSnapshot
        latestAnchorTimestamp[side] = timestamp

        var observation = workingMetrics[side]
        let wasTracked = observation.isTracked
        let now = Date()
        observation.updateCount += 1
        observation.isTracked = handSnapshot.isTracked
        observation.jointCount = handSnapshot.joints.filter(\.isTracked).count
        updateRate(for: side, observation: &observation, now: now)

        if wasTracked && !handSnapshot.isTracked {
            observation.lossCount += 1
            addLog("\(side.title) 추적이 손실되었습니다.")
        } else if !wasTracked && handSnapshot.isTracked {
            addLog("\(side.title) 추적이 시작되거나 복구되었습니다.")
        }

        workingMetrics[side] = observation
        workingMetrics.lastUpdateAt = now
        evaluatePoseFeatures()
        onSnapshotChanged?(latestSnapshot)
        publishMetricsIfNeeded()
        await recordIfNeeded(side: side, event: event, timestamp: timestamp, wallClock: now)
    }

    private func handleRemoved(
        anchor: HandAnchor,
        timestamp: TimeInterval
    ) async {
        guard let side = HandSide(chirality: anchor.chirality) else { return }
        var observation = workingMetrics[side]
        if observation.isTracked {
            observation.lossCount += 1
            addLog("\(side.title) Anchor가 제거되었습니다.")
        }
        observation.isTracked = false
        observation.jointCount = 0
        observation.updateRateHz = 0
        clearFeatureMeasurements(in: &observation)
        workingMetrics[side] = observation
        workingMetrics.lastUpdateAt = Date()
        lastUpdateBySide[side] = nil
        latestAnchorTimestamp[side] = timestamp
        latestSnapshot[side] = HandSnapshot(side: side, isTracked: false, joints: [])
        evaluatePoseFeatures()
        onSnapshotChanged?(latestSnapshot)
        publishMetrics(force: true)
        await recordIfNeeded(side: side, event: "removed", timestamp: timestamp, wallClock: Date())
    }

    private func makeSnapshot(for side: HandSide, anchor: HandAnchor) -> HandSnapshot {
        guard anchor.isTracked, let skeleton = anchor.handSkeleton else {
            return HandSnapshot(side: side, isTracked: false, joints: [])
        }

        let joints = HandJointCatalog.all.map { jointName in
            let joint = skeleton.joint(jointName)
            let originFromJointTransform =
                anchor.originFromAnchorTransform * joint.anchorFromJointTransform
            return HandJointSample(
                name: jointName,
                isTracked: joint.isTracked,
                originFromJointTransform: originFromJointTransform
            )
        }
        return HandSnapshot(side: side, isTracked: true, joints: joints)
    }

    private func evaluatePoseFeatures() {
        workingPoseFeatures = PoseFeatureAdapter.evaluate(
            snapshot: latestSnapshot,
            leftTimestamp: latestAnchorTimestamp[.left],
            rightTimestamp: latestAnchorTimestamp[.right]
        )
        applyFeatureMeasurements(workingPoseFeatures.left, to: .left)
        applyFeatureMeasurements(workingPoseFeatures.right, to: .right)
        workingMetrics.palmCenterDistanceMeters = workingPoseFeatures.bimanual.palmCenterDistanceMeters
        workingMetrics.normalizedPalmCenterDistance = workingPoseFeatures.bimanual.normalizedPalmCenterDistance
    }

    private func applyFeatureMeasurements(
        _ features: HandFeatureDebugSnapshot,
        to side: HandSide
    ) {
        var observation = workingMetrics[side]
        let trackedWrist = latestSnapshot[side]?.joints.first {
            $0.name == .wrist && $0.isTracked
        }
        observation.wristWorldPosition = trackedWrist?.worldPosition
        observation.palmWidthMeters = features.palmWidthMeters
        observation.pinchDistanceMeters = features.thumbIndexTipDistanceMeters
        observation.wristToMiddleTipMeters = features.fingers["middle"]?.tipToWristDistanceMeters
        workingMetrics[side] = observation
    }

    private func recordIfNeeded(
        side: HandSide,
        event: String,
        timestamp: TimeInterval,
        wallClock: Date
    ) async {
        guard recordingState.isRecording else { return }
        let hand = latestSnapshot[side]
        let joints: [JointCaptureInput]
        if let samples = hand?.joints, !samples.isEmpty {
            joints = samples.map {
                JointCaptureInput(
                    name: HandJointCatalog.stableName(for: $0.name),
                    isTracked: $0.isTracked,
                    xMeters: $0.worldPosition.x,
                    yMeters: $0.worldPosition.y,
                    zMeters: $0.worldPosition.z
                )
            }
        } else {
            joints = HandJointCatalog.all.map {
                JointCaptureInput(
                    name: HandJointCatalog.stableName(for: $0),
                    isTracked: false,
                    xMeters: nil,
                    yMeters: nil,
                    zMeters: nil
                )
            }
        }

        do {
            try await recorder.record(
                anchor: AnchorCaptureInput(
                    wallClock: wallClock,
                    anchorTimestampSeconds: timestamp,
                    event: event,
                    side: side == .left ? "left" : "right",
                    handIsTracked: hand?.isTracked ?? false,
                    joints: joints,
                    poseFeatures: workingPoseFeatures,
                    activeMarker: activeMarkerCaptureInput
                )
            )
            recordedAnchorUpdateCount += 1
        } catch {
            recordingState = .failed(error.localizedDescription)
            addLog("Anchor 기록 오류: \(error.localizedDescription)")
        }
    }

    private func makeRecordingMetadata(startedAt: Date) -> VerificationRecordingMetadata {
        let info = Bundle.main.infoDictionary ?? [:]
        return VerificationRecordingMetadata(
            schemaVersion: 2,
            issueNumber: 23,
            handTrackingReferenceCommit: "d3b57bd5e59e2bf4b62ed57ba02b3aa53d23137f",
            poseFeaturesReferenceCommit: "9d8dbae88be48d159f5a39a6d4fb1423e1db3e86",
            startedAt: startedAt,
            deviceModel: UIDevice.current.model,
            systemName: UIDevice.current.systemName,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: info["CFBundleShortVersionString"] as? String ?? "unknown",
            appBuild: info["CFBundleVersion"] as? String ?? "unknown",
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "unknown",
            xcodeBuild: info["DTXcodeBuild"] as? String ?? "unknown",
            sdkName: info["DTSDKName"] as? String ?? "unknown",
            minimumOSVersion: info["MinimumOSVersion"] as? String ?? "unknown",
            coordinateUnit: "meter",
            distanceDisplayUnit: "centimeter"
        )
    }

    private func updateRate(
        for side: HandSide,
        observation: inout HandObservation,
        now: Date
    ) {
        defer { lastUpdateBySide[side] = now }
        guard let previous = lastUpdateBySide[side] else { return }
        let interval = now.timeIntervalSince(previous)
        guard interval > 0 else { return }
        let instantRate = min(240, 1 / interval)
        observation.updateRateHz = observation.updateRateHz == 0
            ? instantRate
            : (observation.updateRateHz * 0.8) + (instantRate * 0.2)
    }

    private func clearLiveTrackingValues() {
        workingMetrics.left.isTracked = false
        workingMetrics.left.jointCount = 0
        clearFeatureMeasurements(in: &workingMetrics.left)
        workingMetrics.right.isTracked = false
        workingMetrics.right.jointCount = 0
        clearFeatureMeasurements(in: &workingMetrics.right)
        workingMetrics.palmCenterDistanceMeters = nil
        workingMetrics.normalizedPalmCenterDistance = nil
        lastUpdateBySide.removeAll()
        metrics = workingMetrics
    }

    private func clearFeatureMeasurements(in observation: inout HandObservation) {
        observation.wristWorldPosition = nil
        observation.palmWidthMeters = nil
        observation.pinchDistanceMeters = nil
        observation.wristToMiddleTipMeters = nil
    }

    private func publishMetricsIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastPublishedAt) >= 0.25 else { return }
        publishMetrics(force: true)
    }

    private func publishMetrics(force: Bool) {
        guard force else { return }
        metrics = workingMetrics
        poseFeatures = workingPoseFeatures
        displaySnapshot = latestSnapshot
        lastPublishedAt = Date()
    }

    private func addLog(_ message: String) {
        logEntries.insert(VerificationLogEntry(timestamp: Date(), message: message), at: 0)
        if logEntries.count > 20 {
            logEntries.removeLast(logEntries.count - 20)
        }
    }

    private func observationReport(_ observation: HandObservation) -> String {
        let position: String
        if let wrist = observation.wristWorldPosition {
            position = String(format: "(%.3f, %.3f, %.3f)m", wrist.x, wrist.y, wrist.z)
        } else {
            position = "없음"
        }

        return "tracked=\(observation.isTracked), joints=\(observation.jointCount), "
            + "rate=\(String(format: "%.1f", observation.updateRateHz))Hz, "
            + "wrist=\(position), palm=\(formatCentimeters(observation.palmWidthMeters)), "
            + "pinch=\(formatCentimeters(observation.pinchDistanceMeters)), "
            + "wrist-middle=\(formatCentimeters(observation.wristToMiddleTipMeters)), "
            + "updates=\(observation.updateCount), losses=\(observation.lossCount)"
    }

    private func formatCentimeters(_ meters: Float?) -> String {
        guard let meters else { return "없음" }
        return String(format: "%.1fcm", meters * 100)
    }

    private func formatRatio(_ ratio: Float?) -> String {
        guard let ratio else { return "없음" }
        return String(format: "%.3f", ratio)
    }

    private func formatMilliseconds(_ seconds: TimeInterval?) -> String {
        guard let seconds else { return "없음" }
        return String(format: "%.1fms", seconds * 1_000)
    }
}
