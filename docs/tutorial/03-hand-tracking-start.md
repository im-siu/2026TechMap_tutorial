# 03. 양손 추적 시작

> 상태: 초안
> 예제 코드 기준: PR #8 / `d3b57bd`

## 이 장의 목표

이 장에서는 Immersive Space가 열린 뒤 `ARKitSession`과 `HandTrackingProvider`를 시작하고, 왼손과 오른손 `HandAnchor`를 안전하게 다루는 흐름을 정리한다.

학습자는 이 장을 통해 다음을 설명할 수 있어야 한다.

- `HandTrackingProvider.isSupported`를 먼저 확인해야 하는 이유
- `ARKitSession.run([provider])`로 Hand Tracking 세션을 시작하는 흐름
- `anchorUpdates`에서 들어오는 `HandAnchor`를 처리하는 방법
- `HandAnchor.chirality`로 왼손과 오른손을 구분하는 방법
- 추적되지 않은 손과 `handSkeleton`이 없는 프레임을 안전하게 처리하는 정책

## 2장에서 이어지는 흐름

2장에서는 버튼을 눌러 Immersive Space를 열고, `ImmersiveView`가 나타나는 흐름을 살펴봤다.

```text
WindowGroup
→ ContentView
→ ToggleImmersiveSpaceButton
→ openImmersiveSpace
→ ImmersiveSpace
→ ImmersiveView
```

3장은 여기서 이어진다. `ImmersiveView`가 나타나면 `HandTrackingService.start()`를 호출해 손 추적 세션을 시작한다.

```text
ImmersiveView
→ HandTrackingService.start()
→ HandTrackingProvider.isSupported
→ ARKitSession.run([provider])
→ HandTrackingProvider.anchorUpdates
→ HandAnchor
→ HandTrackingSnapshot
```

이 장의 목표는 손 관절을 화면에 그리는 것이 아니라, 실제 시각화에 넘길 수 있는 손 추적 입력을 안전하게 준비하는 것이다.

## HandTrackingService의 책임

예제 코드에서 `HandTrackingService`는 ARKit 손 추적과 관련된 생명주기를 담당한다.

```swift
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
}
```

이 객체는 세 가지 일을 맡는다.

- `ARKitSession`과 `HandTrackingProvider`를 시작하고 중지한다.
- `anchorUpdates`에서 들어오는 손 Anchor를 왼손과 오른손으로 나눈다.
- 현재 추적 상태를 `HandTrackingSnapshot`과 상태 문자열로 정리한다.

ARKit 입력을 View 안에 직접 섞지 않고 Service로 분리하면, SwiftUI 화면과 RealityKit 시각화는 "현재 손 추적 상태가 무엇인지"만 받아서 사용할 수 있다.

`@MainActor`는 손 추적 update를 받은 뒤 UI 상태와 RealityKit callback을 같은 메인 액터에서 갱신하기 위한 선택이다. `@Observable`은 `status`, `leftHandSummary`, `rightHandSummary`처럼 SwiftUI 화면이 관찰해야 하는 값을 자동으로 갱신하기 위해 사용한다.

## 지원 여부 먼저 확인하기

손 추적을 시작하기 전에 현재 실행 환경이 ARKit Hand Tracking을 지원하는지 확인한다.

```swift
guard HandTrackingProvider.isSupported else {
    status = .unsupported
    onSnapshotChanged?(.empty)
    return
}
```

이 확인은 Simulator와 실기기 환경을 구분할 때 중요하다. 실행 환경이 Hand Tracking을 지원하지 않으면 세션을 시작하지 않고, 빈 snapshot을 전달해 화면과 시각화가 잘못된 데이터를 사용하지 않게 한다.

문서에서는 이 단계를 "손 추적이 가능하다고 가정하고 바로 시작하는 코드"가 아니라, "지원 여부를 확인한 뒤 가능한 경우에만 시작하는 코드"로 설명한다.

## ARKitSession 시작하기

지원 여부를 통과하면 상태를 `starting`으로 바꾸고 비동기 Task 안에서 세션을 시작한다.

```swift
guard trackingTask == nil else { return }

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
```

`guard trackingTask == nil else { return }`는 이미 실행 중인 손 추적 Task가 있을 때 새 Task를 만들지 않기 위한 방어 코드다. Immersive Space가 다시 나타나거나 `start()`가 연속 호출되더라도 `anchorUpdates`를 듣는 Task가 두 개 이상 생기지 않게 한다.

`session.run([provider])`는 ARKit 세션에 Hand Tracking Provider를 등록하고 실행한다. 예제 코드는 `requestAuthorization(for:)`를 먼저 호출하지 않고, 세션 실행 흐름에서 필요한 권한 요청이 이어지도록 둔다. 튜토리얼 초반에는 권한 요청 단계를 따로 분리하기보다 "세션을 시작하면 필요한 권한 흐름도 함께 진행된다"는 모델로 단순화한다. 자세한 동작은 Apple의 [ARKitSession.run(_:)](<https://developer.apple.com/documentation/arkit/arkitsession/run(_:)>) 문서를 함께 확인한다.

세션 시작에 성공하면 `status`를 `running`으로 바꾸고, `provider.anchorUpdates`를 순회하면서 새로 들어오는 `HandAnchor`를 처리한다.

세션 시작에 실패하면 실패 상태를 기록하고 빈 snapshot을 전달한다. 실패 이유를 상태에 남기면 학습자는 앱이 멈춘 것인지, 권한 또는 실행 환경 문제인지 구분할 수 있다.

## anchorUpdates에서 HandAnchor 받기

`anchorUpdates`는 비동기 sequence다. 새 손 Anchor가 들어올 때마다 `update.anchor`를 꺼내 처리한다.

```swift
for await update in provider.anchorUpdates {
    guard !Task.isCancelled else { return }
    handle(anchor: update.anchor)
}
```

`Task.isCancelled`를 확인하는 이유는 Immersive Space가 닫혀서 `stop()`이 호출되었을 때 더 이상 이전 세션의 업데이트를 처리하지 않기 위해서다.

이 장에서는 `HandAnchor`에서 관절 위치를 바로 그리지 않는다. 먼저 이 Anchor가 왼손인지 오른손인지, 추적 가능한 상태인지, skeleton이 있는지 확인한다.

## 왼손과 오른손 구분하기

`HandAnchor.chirality`는 Anchor가 왼손인지 오른손인지 알려준다. 예제 코드에서는 이를 앱 내부 타입인 `HandSide`로 변환한다.

```swift
enum HandSide: CaseIterable, Hashable {
    case left
    case right

    init?(chirality: HandAnchor.Chirality) {
        switch chirality {
        case .left:
            self = .left
        case .right:
            self = .right
        @unknown default:
            return nil
        }
    }
}
```

알 수 없는 chirality가 들어오면 `nil`을 반환하고 해당 Anchor는 처리하지 않는다.

```swift
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
```

이 흐름 덕분에 왼손과 오른손의 최신 상태를 하나의 `HandTrackingSnapshot` 안에 따로 보관할 수 있다.

## 추적되지 않은 손 처리하기

손 Anchor가 들어왔다고 해서 항상 관절 데이터를 사용할 수 있는 것은 아니다. 예제 코드에서는 손 전체가 추적되지 않거나 skeleton이 없으면 추적되지 않은 손으로 기록한다.

```swift
guard anchor.isTracked, let skeleton = anchor.handSkeleton else {
    return HandSnapshot(side: side, isTracked: false, joints: [])
}
```

이 정책은 안전한 기본값이다.

- 손 전체가 추적되지 않으면 관절 배열을 비운다.
- `handSkeleton`이 없으면 임의 데이터를 만들지 않는다.
- 다음 단계는 `isTracked == false`를 보고 해당 손을 표시하지 않거나 계산에서 제외할 수 있다.

이 장에서는 "추적되지 않은 손도 이전 좌표를 계속 사용한다" 같은 보정은 하지 않는다. smoothing, 유지 시간, 이전 프레임 보정은 이후 심화 단계에서 다룰 수 있다.

## 관절별 추적 상태 처리하기

skeleton이 있어도 모든 관절이 항상 추적되는 것은 아니다. 예제 코드는 catalog에 있는 관절을 순회하면서 추적된 관절만 sample로 만든다.

```swift
let joints = HandJointCatalog.all.compactMap { jointName -> HandJointSample? in
    let joint = skeleton.joint(jointName)
    guard joint.isTracked else { return nil }

    let originFromJointTransform = anchor.originFromAnchorTransform * joint.anchorFromJointTransform
    return HandJointSample(name: jointName, originFromJointTransform: originFromJointTransform)
}
```

여기서 중요한 정책은 누락된 관절을 임의 좌표로 채우지 않는 것이다. 추적되지 않은 관절을 `(0, 0, 0)` 같은 값으로 대체하면 다음 장의 시각화와 5장의 Pose Features 계산이 실제 손 상태와 다른 값을 사용하게 된다.

따라서 `joints.count`는 프레임마다 달라질 수 있다. 4장의 시각화는 snapshot에 들어 있는 관절만 그려야 하고, 5장의 Pose Features 계산은 필요한 관절이 없을 때 계산을 건너뛰거나 별도 정책을 적용해야 한다.

관절 transform 계산과 공간 시각화는 4장에서 더 자세히 다룬다. 3장에서는 "추적된 관절만 다음 단계로 넘긴다"는 정책을 이해하는 데 집중한다.

## 상태를 UI와 시각화에 전달하기

`HandTrackingSnapshot`은 왼손과 오른손의 최신 상태를 담는다.

```swift
struct HandTrackingSnapshot {
    var left: HandSnapshot?
    var right: HandSnapshot?

    static let empty = HandTrackingSnapshot(left: nil, right: nil)
}
```

`HandSnapshot`은 손의 방향, 추적 여부, 관절 sample 목록을 가진다.

```swift
struct HandSnapshot {
    let side: HandSide
    let isTracked: Bool
    let joints: [HandJointSample]
}
```

이 구조를 사용하면 UI는 왼손/오른손 관절 수를 표시할 수 있고, RealityKit 시각화는 현재 추적된 관절만 그릴 수 있다.

다만 `anchorUpdates`는 양손을 항상 같은 timestamp의 한 프레임으로 묶어 전달하지 않는다. 한쪽 손 update가 들어오면 그 손의 최신값을 갱신하고, 반대쪽 손은 이전에 받은 최신값을 유지한다. 그래서 `HandTrackingSnapshot`은 "동시에 촬영된 양손 프레임"이라기보다 "각 손의 가장 최근 값 묶음"에 가깝다. 5장에서 양손 거리나 방향을 계산할 때는 이 시간 차를 어떻게 다룰지 별도 정책이 필요할 수 있다.

```swift
onSnapshotChanged?(latestSnapshot)
```

3장의 끝에서 얻는 결과는 완성된 시각 효과가 아니라, 다음 장에서 시각화할 수 있는 안전한 손 추적 snapshot이다.

## Hand Tracking 중지하기

Immersive Space가 닫히면 `stop()`을 호출해 세션과 상태를 정리한다.

```swift
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
```

중지할 때는 비동기 업데이트 Task를 취소하고, ARKit 세션을 멈추고, 마지막 snapshot을 비운다. 이렇게 해야 Immersive Space를 다시 열었을 때 이전 세션의 관절 상태가 남아 있는 것처럼 보이지 않는다.

## 빌드로 확인할 것과 실기기에서 확인할 것

이 단계에서 빌드로 확인할 수 있는 것은 코드가 visionOS 대상으로 컴파일되고, `ARKitSession`, `HandTrackingProvider`, `anchorUpdates`, `HandAnchor`를 사용하는 구조가 문법과 타입 관점에서 맞는지다.

하지만 빌드가 통과해도 실제 손 추적이 검증된 것은 아니다. 아래 항목은 Apple Vision Pro 실기기에서 따로 확인해야 한다.

- 손 추적 권한 프롬프트가 기대한 시점에 표시되는지
- 실제 왼손과 오른손 `HandAnchor`가 안정적으로 들어오는지
- `HandAnchor.chirality`가 기대대로 왼손과 오른손을 구분하는지
- 손 가림이나 빠른 움직임에서 `isTracked`, `handSkeleton`, `joint.isTracked`가 어떻게 변하는지
- 추적 손실 후 복구될 때 snapshot이 자연스럽게 갱신되는지

Simulator와 Xcode 빌드는 코드 구조를 확인하는 데 도움이 되지만, 실제 손 추적 품질을 검증하지는 못한다.

## 이 장의 완료 기준

- Hand Tracking 세션 시작과 중지 흐름을 설명할 수 있다.
- `HandTrackingProvider.isSupported` 확인이 필요한 이유를 설명할 수 있다.
- `anchorUpdates`에서 들어온 `HandAnchor`를 왼손과 오른손으로 나누는 흐름을 설명할 수 있다.
- 추적되지 않은 손과 누락된 관절을 임의 좌표로 채우지 않는 이유를 설명할 수 있다.
- Xcode 빌드로 확인한 것과 Apple Vision Pro 실기기에서 확인해야 하는 것을 구분할 수 있다.

## 이전 장 / 다음 장

- 이전: [02. 첫 Immersive Space](./02-first-immersive-space.md)
- 다음: 04. 관절을 공간에 그리기: 작성 예정
