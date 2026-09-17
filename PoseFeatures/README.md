# PoseFeatures

`PoseFeatures` is a pure Swift package for building and evaluating the
single-frame features used by the Hand Jutsu tutorial.

## Verification record schema

`PoseFeatureVerificationRecord` currently uses schema version `1`. Decode
records with `PoseFeatureVerificationRecord.decode(from:)`; it rejects an
unsupported future schema version. A breaking record change must increment the
schema version and document how version `1` records are interpreted or
migrated.

The package intentionally does not include multi-frame stabilization,
hysteresis, or spell triggering. Those concerns belong to a later
`GestureClassifier` or state-machine layer.
