import Foundation
import PoseFeatures

func encodeVerificationRecord(
    leftInput: HandPoseInput,
    rightInput: HandPoseInput
) throws -> Data {
    let record = PoseFeatureVerificationAdapter.makeRecord(
        leftInput: leftInput,
        rightInput: rightInput
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return try encoder.encode(record)
}

// schemaVersion 1 records contain the bilateral pinch metrics.
// A future reader rejects an unsupported schema version before decoding metrics.
