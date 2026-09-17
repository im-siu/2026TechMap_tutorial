import Foundation

public struct HandPoseFeatureRecord: Codable, Sendable {
    public let side: HandSide
    public let availability: PoseFeatureAvailability
    public let jointCoverageRatio: Float
    public let availableFeatures: [PoseFeatureName]
    public let missingFeatures: [PoseFeatureName]
    public let missingJoints: [HandJoint]
}

public struct BilateralPinchMetricRecord: Codable, Sendable {
    public let leftNormalizedPinchDistance: Float?
    public let rightNormalizedPinchDistance: Float?
}

public struct PoseFeatureVerificationRecord: Codable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let capturedAt: Date
    public let targetPose: TargetPose
    public let evaluationStatus: PoseEvaluationStatus
    public let hands: [HandPoseFeatureRecord]
    public let metrics: BilateralPinchMetricRecord

    public static func encode(_ record: Self) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(record)
    }

    public static func decode(from data: Data) throws -> Self {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let record = try decoder.decode(Self.self, from: data)

        guard record.schemaVersion == currentSchemaVersion else {
            throw PoseFeatureVerificationRecordDecodingError.unsupportedSchemaVersion(record.schemaVersion)
        }

        return record
    }
}

public enum PoseFeatureVerificationRecordDecodingError: Error, Equatable, Sendable {
    case unsupportedSchemaVersion(Int)
}

public enum PoseFeatureVerificationAdapter {
    public static func makeRecord(
        leftInput: HandPoseInput,
        rightInput: HandPoseInput,
        capturedAt: Date = .now
    ) -> PoseFeatureVerificationRecord {
        let leftFeature = BilateralPinchPose.makeFeature(from: leftInput)
        let rightFeature = BilateralPinchPose.makeFeature(from: rightInput)
        let evaluation = BilateralPinchPose.evaluate(left: leftFeature, right: rightFeature)

        return PoseFeatureVerificationRecord(
            schemaVersion: PoseFeatureVerificationRecord.currentSchemaVersion,
            capturedAt: capturedAt,
            targetPose: .bilateralPinch,
            evaluationStatus: evaluation.status,
            hands: [record(from: leftFeature), record(from: rightFeature)],
            metrics: BilateralPinchMetricRecord(
                leftNormalizedPinchDistance: evaluation.leftNormalizedPinchDistance,
                rightNormalizedPinchDistance: evaluation.rightNormalizedPinchDistance
            )
        )
    }

    private static func record(from feature: HandPoseFeature) -> HandPoseFeatureRecord {
        HandPoseFeatureRecord(
            side: feature.side,
            availability: feature.availability,
            jointCoverageRatio: feature.jointCoverageRatio,
            availableFeatures: feature.availableFeatures,
            missingFeatures: feature.missingFeatures,
            missingJoints: feature.missingJoints
        )
    }
}
