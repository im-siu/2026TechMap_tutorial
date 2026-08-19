import Foundation

nonisolated struct JointCaptureInput: Codable, Sendable {
    let name: String
    let isTracked: Bool
    let xMeters: Float?
    let yMeters: Float?
    let zMeters: Float?
}

nonisolated struct AnchorCaptureInput: Codable, Sendable {
    let wallClock: Date
    let anchorTimestampSeconds: TimeInterval
    let event: String
    let side: String
    let handIsTracked: Bool
    let joints: [JointCaptureInput]
    let poseFeatures: PoseFeatureEvaluationSnapshot
}

nonisolated struct MarkerCaptureInput: Codable, Sendable {
    let wallClock: Date
    let elapsedSeconds: TimeInterval
    let index: Int
    let label: String
}

nonisolated struct VerificationRecordingMetadata: Codable, Sendable {
    let schemaVersion: Int
    let issueNumber: Int
    let handTrackingReferenceCommit: String
    let poseFeaturesReferenceCommit: String
    let startedAt: Date
    let deviceModel: String
    let systemName: String
    let systemVersion: String
    let appVersion: String
    let appBuild: String
    let bundleIdentifier: String
    let xcodeBuild: String
    let sdkName: String
    let minimumOSVersion: String
    let coordinateUnit: String
    let distanceDisplayUnit: String
}

nonisolated struct VerificationRecordingStopContext: Codable, Sendable {
    let leftTrackingLossCount: Int
    let rightTrackingLossCount: Int
    let notes: String
}

nonisolated struct VerificationRecordingStart: Sendable {
    let sessionID: String
    let startedAt: Date
    let folderURL: URL
}

nonisolated struct VerificationRecordingExport: Sendable {
    let sessionID: String
    let folderURL: URL
    let files: [URL]
}

nonisolated private struct AnchorLogEnvelope: Encodable {
    let kind = "anchor"
    let schemaVersion = 1
    let sessionID: String
    let sequence: Int
    let elapsedAnchorSeconds: TimeInterval
    let elapsedWallSeconds: TimeInterval
    let payload: AnchorCaptureInput
}

nonisolated private struct MarkerLogEnvelope: Encodable {
    let kind = "marker"
    let schemaVersion = 1
    let sessionID: String
    let payload: MarkerCaptureInput
}

nonisolated private struct MetadataFile: Encodable {
    let sessionID: String
    let metadata: VerificationRecordingMetadata
}

nonisolated private struct SummaryFile: Encodable {
    let sessionID: String
    let stoppedAt: Date
    let durationSeconds: TimeInterval
    let anchorUpdateCount: Int
    let leftUpdateCount: Int
    let rightUpdateCount: Int
    let trackedJointRowCount: Int
    let untrackedJointRowCount: Int
    let leftFeatureSuccessCount: Int
    let leftFeatureFailureCount: Int
    let rightFeatureSuccessCount: Int
    let rightFeatureFailureCount: Int
    let bimanualFeatureSuccessCount: Int
    let bimanualFeatureFailureCount: Int
    let markerCount: Int
    let firstAnchorTimestampSeconds: TimeInterval?
    let lastAnchorTimestampSeconds: TimeInterval?
    let stopContext: VerificationRecordingStopContext
}

actor VerificationSessionRecorder {
    private var sessionID: String?
    private var startedAt: Date?
    private var folderURL: URL?
    private var firstAnchorTimestamp: TimeInterval?
    private var lastAnchorTimestamp: TimeInterval?
    private var sequence = 0

    private var rawHandle: FileHandle?
    private var jointsHandle: FileHandle?
    private var featuresHandle: FileHandle?
    private var markersHandle: FileHandle?

    private var rawURL: URL?
    private var jointsURL: URL?
    private var featuresURL: URL?
    private var markersURL: URL?
    private var metadataURL: URL?
    private var summaryURL: URL?

    private var leftUpdateCount = 0
    private var rightUpdateCount = 0
    private var trackedJointRowCount = 0
    private var untrackedJointRowCount = 0
    private var leftFeatureSuccessCount = 0
    private var leftFeatureFailureCount = 0
    private var rightFeatureSuccessCount = 0
    private var rightFeatureFailureCount = 0
    private var bimanualFeatureSuccessCount = 0
    private var bimanualFeatureFailureCount = 0
    private var markerCount = 0

    func start(metadata: VerificationRecordingMetadata) throws -> VerificationRecordingStart {
        guard sessionID == nil else {
            throw RecorderError.alreadyRecording
        }

        let newSessionID = Self.makeSessionID(date: metadata.startedAt)
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let root = documents.appendingPathComponent(
            "HandTrackingVerifications",
            isDirectory: true
        )
        let folder = root.appendingPathComponent(newSessionID, isDirectory: true)
        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )

        let newRawURL = folder.appendingPathComponent("anchors.ndjson")
        let newJointsURL = folder.appendingPathComponent("joints.csv")
        let newFeaturesURL = folder.appendingPathComponent("features.csv")
        let newMarkersURL = folder.appendingPathComponent("markers.csv")
        let newMetadataURL = folder.appendingPathComponent("metadata.json")
        let newSummaryURL = folder.appendingPathComponent("summary.json")

        rawHandle = try Self.makeFileHandle(at: newRawURL)
        jointsHandle = try Self.makeFileHandle(at: newJointsURL)
        featuresHandle = try Self.makeFileHandle(at: newFeaturesURL)
        markersHandle = try Self.makeFileHandle(at: newMarkersURL)

        try Self.writeJSON(
            MetadataFile(sessionID: newSessionID, metadata: metadata),
            to: newMetadataURL
        )
        try writeLine(Self.jointsCSVHeader, to: jointsHandle)
        try writeLine(Self.featuresCSVHeader, to: featuresHandle)
        try writeLine(Self.markersCSVHeader, to: markersHandle)

        sessionID = newSessionID
        startedAt = metadata.startedAt
        folderURL = folder
        rawURL = newRawURL
        jointsURL = newJointsURL
        featuresURL = newFeaturesURL
        markersURL = newMarkersURL
        metadataURL = newMetadataURL
        summaryURL = newSummaryURL

        return VerificationRecordingStart(
            sessionID: newSessionID,
            startedAt: metadata.startedAt,
            folderURL: folder
        )
    }

    func record(anchor input: AnchorCaptureInput) throws {
        guard let sessionID, let startedAt else { return }

        if firstAnchorTimestamp == nil {
            firstAnchorTimestamp = input.anchorTimestampSeconds
        }
        lastAnchorTimestamp = input.anchorTimestampSeconds
        sequence += 1

        let anchorElapsed = input.anchorTimestampSeconds - (firstAnchorTimestamp ?? 0)
        let wallElapsed = input.wallClock.timeIntervalSince(startedAt)
        let envelope = AnchorLogEnvelope(
            sessionID: sessionID,
            sequence: sequence,
            elapsedAnchorSeconds: anchorElapsed,
            elapsedWallSeconds: wallElapsed,
            payload: input
        )
        try writeNDJSON(envelope, to: rawHandle)

        if input.side == "left" {
            leftUpdateCount += 1
        } else {
            rightUpdateCount += 1
        }

        for joint in input.joints {
            if joint.isTracked {
                trackedJointRowCount += 1
            } else {
                untrackedJointRowCount += 1
            }
            try writeLine(
                jointCSVRow(
                    sessionID: sessionID,
                    sequence: sequence,
                    elapsedAnchor: anchorElapsed,
                    input: input,
                    joint: joint
                ),
                to: jointsHandle
            )
        }

        updateFeatureCounters(input.poseFeatures)
        try writeLine(
            featuresCSVRow(
                sessionID: sessionID,
                sequence: sequence,
                elapsedAnchor: anchorElapsed,
                input: input
            ),
            to: featuresHandle
        )
    }

    func record(marker: MarkerCaptureInput) throws {
        guard let sessionID else { return }
        markerCount += 1
        try writeNDJSON(
            MarkerLogEnvelope(sessionID: sessionID, payload: marker),
            to: rawHandle
        )
        try writeLine(
            [
                sessionID,
                String(marker.index),
                Self.float(marker.elapsedSeconds),
                ISO8601DateFormatter().string(from: marker.wallClock),
                marker.label
            ].map(Self.csvEscape).joined(separator: ","),
            to: markersHandle
        )
    }

    func stop(
        context: VerificationRecordingStopContext
    ) throws -> VerificationRecordingExport? {
        guard let sessionID,
              let startedAt,
              let folderURL,
              let rawURL,
              let jointsURL,
              let featuresURL,
              let markersURL,
              let metadataURL,
              let summaryURL else { return nil }

        let stoppedAt = Date()
        let summary = SummaryFile(
            sessionID: sessionID,
            stoppedAt: stoppedAt,
            durationSeconds: stoppedAt.timeIntervalSince(startedAt),
            anchorUpdateCount: sequence,
            leftUpdateCount: leftUpdateCount,
            rightUpdateCount: rightUpdateCount,
            trackedJointRowCount: trackedJointRowCount,
            untrackedJointRowCount: untrackedJointRowCount,
            leftFeatureSuccessCount: leftFeatureSuccessCount,
            leftFeatureFailureCount: leftFeatureFailureCount,
            rightFeatureSuccessCount: rightFeatureSuccessCount,
            rightFeatureFailureCount: rightFeatureFailureCount,
            bimanualFeatureSuccessCount: bimanualFeatureSuccessCount,
            bimanualFeatureFailureCount: bimanualFeatureFailureCount,
            markerCount: markerCount,
            firstAnchorTimestampSeconds: firstAnchorTimestamp,
            lastAnchorTimestampSeconds: lastAnchorTimestamp,
            stopContext: context
        )
        try Self.writeJSON(summary, to: summaryURL)

        try closeHandles()
        let export = VerificationRecordingExport(
            sessionID: sessionID,
            folderURL: folderURL,
            files: [rawURL, jointsURL, featuresURL, markersURL, metadataURL, summaryURL]
        )
        reset()
        return export
    }

    private func updateFeatureCounters(_ evaluation: PoseFeatureEvaluationSnapshot) {
        if evaluation.left.isSuccess {
            leftFeatureSuccessCount += 1
        } else {
            leftFeatureFailureCount += 1
        }
        if evaluation.right.isSuccess {
            rightFeatureSuccessCount += 1
        } else {
            rightFeatureFailureCount += 1
        }
        if evaluation.bimanual.isSuccess {
            bimanualFeatureSuccessCount += 1
        } else {
            bimanualFeatureFailureCount += 1
        }
    }

    private func jointCSVRow(
        sessionID: String,
        sequence: Int,
        elapsedAnchor: TimeInterval,
        input: AnchorCaptureInput,
        joint: JointCaptureInput
    ) -> String {
        [
            sessionID,
            String(sequence),
            Self.float(input.anchorTimestampSeconds),
            Self.float(elapsedAnchor),
            input.side,
            input.event,
            String(input.handIsTracked),
            joint.name,
            String(joint.isTracked),
            Self.float(joint.xMeters),
            Self.float(joint.yMeters),
            Self.float(joint.zMeters)
        ].map(Self.csvEscape).joined(separator: ",")
    }

    private func featuresCSVRow(
        sessionID: String,
        sequence: Int,
        elapsedAnchor: TimeInterval,
        input: AnchorCaptureInput
    ) -> String {
        var values = [
            sessionID,
            String(sequence),
            Self.float(input.anchorTimestampSeconds),
            Self.float(elapsedAnchor),
            input.side,
            input.event
        ]
        values += Self.handFeatureValues(input.poseFeatures.left)
        values += Self.handFeatureValues(input.poseFeatures.right)

        let both = input.poseFeatures.bimanual
        values += [
            both.errorCode ?? "",
            Self.float(both.palmCenterDistanceMeters),
            Self.float(both.normalizedPalmCenterDistance),
            Self.vectorComponent(both.leftToRightDirection, keyPath: \.x),
            Self.vectorComponent(both.leftToRightDirection, keyPath: \.y),
            Self.vectorComponent(both.leftToRightDirection, keyPath: \.z),
            Self.float(both.palmNormalAlignment),
            Self.float(both.leftPalmFacingRight),
            Self.float(both.rightPalmFacingLeft),
            Self.float(both.mutualFacingScore),
            Self.float(both.timestampSkewSeconds)
        ]
        return values.map(Self.csvEscape).joined(separator: ",")
    }

    private static func handFeatureValues(_ hand: HandFeatureDebugSnapshot) -> [String] {
        var values = [
            hand.isSuccess ? "success" : "failure",
            hand.errorCode ?? "",
            hand.missingJoints.joined(separator: ";"),
            String(hand.sampleJointCount),
            vectorComponent(hand.palmCenterMeters, keyPath: \.x),
            vectorComponent(hand.palmCenterMeters, keyPath: \.y),
            vectorComponent(hand.palmCenterMeters, keyPath: \.z),
            vectorComponent(hand.palmNormal, keyPath: \.x),
            vectorComponent(hand.palmNormal, keyPath: \.y),
            vectorComponent(hand.palmNormal, keyPath: \.z),
            float(hand.palmWidthMeters),
            float(hand.palmLengthMeters),
            float(hand.geometricMeanMeters),
            float(hand.thumbIndexTipDistanceMeters),
            float(hand.normalizedThumbIndexTipDistance)
        ]

        for finger in ["thumb", "index", "middle", "ring", "little"] {
            let feature = hand.fingers[finger]
            values += [
                float(feature?.straightness),
                float(feature?.normalizedTipToWristDistance),
                feature?.bendAnglesRadians.map { float($0) }.joined(separator: ";") ?? ""
            ]
        }
        return values
    }

    private func writeNDJSON<T: Encodable>(_ value: T, to handle: FileHandle?) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        try handle?.write(contentsOf: data)
        try handle?.write(contentsOf: Data([0x0A]))
    }

    private func writeLine(_ line: String, to handle: FileHandle?) throws {
        try handle?.write(contentsOf: Data((line + "\n").utf8))
    }

    private func closeHandles() throws {
        for handle in [rawHandle, jointsHandle, featuresHandle, markersHandle] {
            try handle?.synchronize()
            try handle?.close()
        }
        rawHandle = nil
        jointsHandle = nil
        featuresHandle = nil
        markersHandle = nil
    }

    private func reset() {
        sessionID = nil
        startedAt = nil
        folderURL = nil
        firstAnchorTimestamp = nil
        lastAnchorTimestamp = nil
        sequence = 0
        rawURL = nil
        jointsURL = nil
        featuresURL = nil
        markersURL = nil
        metadataURL = nil
        summaryURL = nil
        leftUpdateCount = 0
        rightUpdateCount = 0
        trackedJointRowCount = 0
        untrackedJointRowCount = 0
        leftFeatureSuccessCount = 0
        leftFeatureFailureCount = 0
        rightFeatureSuccessCount = 0
        rightFeatureFailureCount = 0
        bimanualFeatureSuccessCount = 0
        bimanualFeatureFailureCount = 0
        markerCount = 0
    }

    private static func makeSessionID(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "HT-\(formatter.string(from: date))-\(UUID().uuidString.prefix(6))"
    }

    private static func makeFileHandle(at url: URL) throws -> FileHandle {
        guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
            throw RecorderError.cannotCreateFile(url.lastPathComponent)
        }
        return try FileHandle(forWritingTo: url)
    }

    private static func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(value).write(to: url, options: .atomic)
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func float<T: BinaryFloatingPoint>(_ value: T?) -> String {
        guard let value else { return "" }
        return String(format: "%.8f", Double(value))
    }

    private static func vectorComponent(
        _ vector: SIMD3<Float>?,
        keyPath: KeyPath<SIMD3<Float>, Float>
    ) -> String {
        guard let vector else { return "" }
        return float(vector[keyPath: keyPath])
    }

    private static let jointsCSVHeader = [
        "session_id", "sequence", "anchor_timestamp_s", "elapsed_anchor_s",
        "side", "event", "hand_tracked", "joint", "joint_tracked",
        "x_m", "y_m", "z_m"
    ].joined(separator: ",")

    private static let featuresCSVHeader: String = {
        var columns = [
            "session_id", "sequence", "anchor_timestamp_s", "elapsed_anchor_s",
            "updated_side", "event"
        ]
        for side in ["left", "right"] {
            columns += [
                "\(side)_status", "\(side)_error", "\(side)_missing_joints",
                "\(side)_sample_joint_count", "\(side)_palm_center_x_m",
                "\(side)_palm_center_y_m", "\(side)_palm_center_z_m",
                "\(side)_palm_normal_x", "\(side)_palm_normal_y",
                "\(side)_palm_normal_z", "\(side)_palm_width_m",
                "\(side)_palm_length_m", "\(side)_geometric_mean_m",
                "\(side)_thumb_index_distance_m", "\(side)_normalized_thumb_index"
            ]
            for finger in ["thumb", "index", "middle", "ring", "little"] {
                columns += [
                    "\(side)_\(finger)_straightness",
                    "\(side)_\(finger)_normalized_tip_wrist",
                    "\(side)_\(finger)_bend_radians"
                ]
            }
        }
        columns += [
            "bimanual_error", "palm_center_distance_m",
            "normalized_palm_center_distance", "left_to_right_x",
            "left_to_right_y", "left_to_right_z", "palm_normal_alignment",
            "left_palm_facing_right", "right_palm_facing_left",
            "mutual_facing_score", "hand_timestamp_skew_s"
        ]
        return columns.joined(separator: ",")
    }()

    private static let markersCSVHeader =
        "session_id,marker_index,elapsed_wall_s,wall_clock,label"
}

enum RecorderError: LocalizedError {
    case alreadyRecording
    case cannotCreateFile(String)

    var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            "이미 기록 중입니다."
        case .cannotCreateFile(let name):
            "\(name) 파일을 만들 수 없습니다."
        }
    }
}
