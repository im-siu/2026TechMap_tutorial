# 04. 관절을 공간에 그리기

> 상태: 코드 구조 검증 완료, Apple Vision Pro 실기기 미검증
>
> 예제 코드 기준: PR #8 / 커밋 [`d3b57bd`](https://github.com/im-siu/2026TechMap_tutorial/commit/d3b57bd5e59e2bf4b62ed57ba02b3aa53d23137f)

이전: 3장 양손 추적 시작(작성 예정) · 다음: 5장 Pose Features로 이어가기(작성 예정)

## 이 장에서 만들 결과

3장에서 받은 `HandTrackingSnapshot`을 RealityKit 시각화 계층에 전달해 왼손 관절은 파란 구체, 오른손 관절은 분홍 구체로 표현한다.

이 장은 3장에서 `HandTrackingService`, `HandTrackingSnapshot`과 `HandJointSample`이 준비됐다고 가정한다. 여기서는 ARKit 세션을 다시 설명하지 않고, 제공된 snapshot을 RealityKit 장면에 어떻게 반영할지에 집중한다. 코드 조각은 위에 연결한 PR #8 기준 구현에서 가져왔다.

이 장을 마치면 다음을 설명할 수 있다.

- 관절 Entity를 시작할 때 한 번 만들고 이후에는 transform과 표시 상태만 갱신하는 이유
- Hand Anchor 기준 관절 transform을 월드 transform으로 바꾸는 행렬 곱 순서
- `setTransformMatrix(_:relativeTo: nil)`에서 `nil`이 월드 공간을 뜻하는 이유
- 손이나 관절의 추적 상태가 불충분할 때 Entity를 숨기는 현재 정책
- 시각화에 사용한 월드 위치가 5장 Pose Features 입력으로 이어지는 방법

## 전체 흐름

```text
HandTrackingProvider.anchorUpdates
→ HandTrackingService가 HandSnapshot 생성
→ HandTrackingSnapshot(left/right)
→ HandJointVisualizer.apply(_:)
→ 관절별 ModelEntity transform 갱신
→ 이번 snapshot에 없는 Entity 숨김
```

`HandTrackingService`는 ARKit 입력과 좌표 계산을 담당하고, `HandJointVisualizer`는 전달받은 결과를 RealityKit Entity에 반영한다. 입력 수집과 화면 표현을 분리하면 5장에서 같은 snapshot을 시각화가 아닌 특징 계산에도 재사용할 수 있다.

두 타입은 모두 `@MainActor`에서 동작한다. ARKit update를 받은 뒤 RealityKit Entity를 바꾸는 callback도 메인 액터에서 실행되므로, 추적 작업이 별도 `Task`를 사용하더라도 장면 변경의 실행 위치가 흩어지지 않는다.

## 1단계: 관절 Entity를 미리 만든다

관절 update가 들어올 때마다 Entity를 새로 만들면 객체 생성과 장면 트리 변경이 매 프레임 반복된다. 현재 Spike는 초기화 시 좌우 손의 관절 Entity를 한 번 만들고, 처음에는 모두 숨겨 둔다.

```swift
private func createJointEntities() {
    for side in HandSide.allCases {
        var sideEntities: [HandSkeleton.JointName: ModelEntity] = [:]

        for jointName in HandJointCatalog.all {
            let entity = ModelEntity(
                mesh: .generateSphere(radius: 0.008),
                materials: [material(for: side)]
            )
            entity.isEnabled = false
            rootEntity.addChild(entity)
            sideEntities[jointName] = entity
        }

        jointEntities[side] = sideEntities
    }
}
```

`rootEntity`는 좌우 손의 모든 관절 Entity를 묶는 컨테이너다. `RealityView`에는 이 root만 한 번 추가하고, 이후에는 이미 연결된 자식 Entity를 찾아 갱신한다. 관절별 Entity를 매 update마다 장면에 직접 추가하거나 제거하지 않는 이유도 여기에 있다.

구체 반지름 `0.008`은 RealityKit의 미터 단위로 8mm다. 실제 관절 크기를 재현한 값이 아니라, 손을 지나치게 가리지 않으면서 관절 위치를 구분하기 위한 Spike의 디버그 시작값이다. 다른 시야 거리나 표시 목적에서는 크기를 다시 조정해야 한다.

`jointEntities`는 손 방향과 관절 이름을 키로 사용한다.

```text
left  + wrist     → 왼손 손목 구체
left  + thumbTip  → 왼손 엄지 끝 구체
right + wrist     → 오른손 손목 구체
right + thumbTip  → 오른손 엄지 끝 구체
```

이렇게 조회 키를 정해 두면 snapshot에 들어온 관절을 같은 Entity에 반복 적용할 수 있다.

## 2단계: 관절 transform을 월드 공간으로 바꾼다

ARKit의 `HandAnchor.originFromAnchorTransform`은 손 Anchor를 월드 원점 기준으로 표현한다. `Joint.anchorFromJointTransform`은 관절을 Hand Anchor 기준으로 표현한다. 따라서 현재 Spike는 두 행렬을 다음 순서로 곱한다.

```swift
let originFromJointTransform =
    anchor.originFromAnchorTransform * joint.anchorFromJointTransform
```

```text
월드 원점 ← 손 Anchor ← 관절
originFromAnchorTransform * anchorFromJointTransform
= originFromJointTransform
```

행렬 곱은 순서를 바꾸면 의미가 달라진다. 관절의 로컬 transform에 손 Anchor의 월드 transform을 먼저 연결해야 최종 결과가 월드 좌표계에 놓인다.

Apple 문서에서도 [`originFromAnchorTransform`](https://developer.apple.com/documentation/arkit/handanchor/originfromanchortransform)은 손 Anchor의 월드 위치와 방향, [`anchorFromJointTransform`](https://developer.apple.com/documentation/arkit/handskeleton/joint/anchorfromjointtransform)은 Hand Anchor 기준 관절 위치와 방향으로 설명한다.

## 3단계: 같은 Entity의 transform을 갱신한다

`HandJointVisualizer`는 snapshot의 좌우 손을 각각 적용한다.

```swift
func apply(_ snapshot: HandTrackingSnapshot) {
    apply(hand: snapshot.left, side: .left)
    apply(hand: snapshot.right, side: .right)
}
```

추적 중인 관절은 기존 Entity를 찾아 월드 transform을 적용하고 표시한다.

```swift
for joint in hand.joints {
    guard let entity = jointEntities[side]?[joint.name] else { continue }

    entity.setTransformMatrix(
        joint.originFromJointTransform,
        relativeTo: nil
    )
    entity.isEnabled = true
    visibleJointNames.insert(joint.name)
}
```

RealityKit의 [`setTransformMatrix(_:relativeTo:)`](https://developer.apple.com/documentation/realitykit/hastransform/settransformmatrix(_:relativeto:))에서 기준 Entity를 `nil`로 전달하면 행렬을 월드 공간 기준으로 적용한다. 앞 단계에서 이미 월드 transform을 만들었으므로 별도의 부모 Entity 기준 변환을 다시 수행하지 않는다.

## 4단계: 이번 snapshot에 없는 관절을 숨긴다

이전 프레임에서 보이던 Entity를 그대로 두면 추적이 끊겼을 때 구체가 공간에 남아 보일 수 있다. 현재 snapshot에서 갱신한 관절 이름을 모은 뒤, 포함되지 않은 Entity를 숨긴다.

```swift
for (jointName, entity) in jointEntities[side] ?? [:]
where !visibleJointNames.contains(jointName) {
    entity.isEnabled = false
}
```

손 전체가 추적되지 않으면 해당 손의 Entity를 모두 숨긴다.

```swift
guard let hand, hand.isTracked else {
    setJointEntitiesEnabled(false, for: side)
    return
}
```

현재 PR #8의 `HandTrackingService`는 `Joint.isTracked == false`인 관절을 snapshot에서 제외한다. 따라서 시각화 계층은 누락된 관절을 임의 위치에 그리지 않는다.

> 주의: 이것은 현재 Spike의 보수적인 시각화 정책이다. Apple의 [`Joint.isTracked`](https://developer.apple.com/documentation/arkit/handskeleton/joint/istracked) 문서는 가림 등으로 `false`여도 ARKit이 추정 transform을 제공할 수 있으며, 관절 가림이 예상되는 제스처에서는 이 값을 무조건 제외하지 말라고 안내한다. 실제 앱에서 추정 transform을 사용할지, 숨길지, 잠깐 유지할지는 실기기 로그와 사용 목적을 확인한 뒤 결정해야 한다.

## 5단계: RealityView에 시각화 root를 연결한다

`ImmersiveView`는 시각화 root Entity를 장면에 한 번 추가하고 snapshot callback에서 갱신을 전달한다.

```swift
RealityView { content in
    content.add(visualizer.rootEntity)
    appModel.handTracking.onSnapshotChanged = { snapshot in
        visualizer.apply(snapshot)
    }
    appModel.handTracking.start()
}
```

화면이 사라질 때는 tracking task를 중지하고 callback을 해제한다. 이렇게 해야 다시 Immersive Space를 열었을 때 이전 callback이 남아 중복 실행되는 일을 피할 수 있다.

## 5장으로 연결하기

구체를 그릴 때 사용한 `originFromJointTransform`의 네 번째 열에는 관절의 월드 위치가 들어 있다.

```swift
let column = joint.originFromJointTransform.columns.3
let position = SIMD3<Float>(column.x, column.y, column.z)
```

ARKit transform의 translation 단위는 미터이며, `SIMD3`로 바꾸면 회전과 크기 정보는 제외되고 위치만 남는다. 5장에서 거리와 방향을 비교하려면 모든 관절이 같은 월드 원점과 같은 단위를 사용해야 한다.

4장에서는 전체 4×4 transform을 RealityKit Entity에 적용한다. 5장에서는 같은 transform에서 위치만 꺼내 ARKit에 의존하지 않는 Pose Features 입력으로 변환한다.

```text
originFromJointTransform
├─ 4장: 전체 행렬 → ModelEntity 시각화
└─ 5장: translation → SIMD3<Float> 특징 계산 입력
```

## 확인 방법

### 실기기 없이 확인한 범위

- PR #8 커밋 `d3b57bd`의 코드 구조와 이 장의 코드 조각을 대조했다.
- 관절 Entity의 생성과 갱신이 분리되어 있음을 확인했다.
- 월드 transform 곱 순서와 `relativeTo: nil`의 의미를 Apple 공식 문서와 대조했다.
- 추적되지 않은 손과 누락 관절을 임의 위치에 표시하지 않는 현재 정책을 확인했다.

### Apple Vision Pro에서 확인할 범위

- 실제 왼손과 오른손에 각 색상의 관절 구체가 표시되는지
- 손의 이동과 회전을 구체가 올바르게 따라오는지
- 좌표 변환 결과가 기대한 월드 위치에 놓이는지
- 빠른 움직임과 손 가림에서 Entity가 남거나 튀지 않는지
- `Joint.isTracked == false`일 때 숨김과 추정 transform 사용 중 어느 정책이 더 자연스러운지

이 항목들은 이 장의 문서 작성 완료와 별개인 **실기기 미검증 항목**이다.

## 문제 해결

### 구체가 원점에 모인다

- `originFromAnchorTransform * anchorFromJointTransform` 순서인지 확인한다.
- translation을 꺼내기 전에 행렬이 월드 transform인지 확인한다.
- 누락된 관절을 `.zero`로 채우지 않았는지 확인한다.

### 추적이 끊긴 뒤 구체가 남는다

- 현재 snapshot에 없던 관절 Entity를 `isEnabled = false`로 바꾸는지 확인한다.
- 손 전체가 추적되지 않을 때 해당 손의 모든 Entity를 숨기는지 확인한다.

### 좌우 손 색상이 바뀐다

- `HandAnchor.chirality`가 `HandSide`로 올바르게 변환됐는지 확인한다.
- `jointEntities`를 `[HandSide: [JointName: ModelEntity]]` 형태로 분리했는지 확인한다.

## 이 장의 완료 기준

- Entity 생성과 매 프레임 갱신의 책임을 구분할 수 있다.
- 관절 월드 transform의 곱 순서를 설명할 수 있다.
- `relativeTo: nil`이 월드 공간을 의미함을 설명할 수 있다.
- 현재 추적 손실 정책과 실기기에서 다시 결정할 정책을 구분할 수 있다.
- 시각화에 사용한 좌표가 5장 Pose Features 입력으로 이어지는 흐름을 설명할 수 있다.

이전: 3장 양손 추적 시작(작성 예정) · 다음: 5장 Pose Features로 이어가기(작성 예정)
