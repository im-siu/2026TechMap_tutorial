# 05. Pose Features로 이어가기

> 상태: 합성 좌표·코드 수준 입력 계약 검증 완료, 앱 종단 간·실기기 미검증
>
> 담당: @sueheo · 교차 리뷰: @im-siu
>
> 기준: Issue #6, #16 / PR #7 커밋 [`9d8dbae`](https://github.com/im-siu/2026TechMap_tutorial/commit/9d8dbae) / PR #8 커밋 [`d3b57bd`](https://github.com/im-siu/2026TechMap_tutorial/commit/d3b57bd5e59e2bf4b62ed57ba02b3aa53d23137f)

[이전: 4장 관절을 공간에 그리기](./04-joint-visualization.md)

## 이 장에서 만들 결과

4장에서 RealityKit 구체를 그릴 때 사용한 관절 월드 transform을 `SIMD3<Float>` 위치로 바꾸고, ARKit에 의존하지 않는 Pose Features 계산의 입력으로 전달하는 구조를 이해한다.

이 장은 완성된 손 모양 분류기를 만들지 않는다. 다음 판정에 사용할 **재료**를 계산하는 데 집중한다.

- 손바닥 크기와 중심
- 손바닥 법선
- 다섯 손가락의 직진도와 굽힘 각도
- 손목–손끝 거리와 엄지–검지 끝 거리
- 양손 중심 거리, 방향과 마주 보는 정도

## 확인된 범위부터 구분하기

현재 두 Spike의 연결 상태는 다음과 같다.

| 단계 | 상태 | 근거 |
| --- | --- | --- |
| Hand Tracking snapshot 구조 | 코드 확인 | PR #8 `d3b57bd` |
| Pose Features 순수 Swift 계산 | 합성 좌표 테스트 확인 | PR #7 `9d8dbae`, 12 tests |
| 관절 이름과 오류 계약 호환성 | 코드 수준 테스트 확인 | PR #7 `9d8dbae` |
| 실제 앱의 ARKit 어댑터 | 미구현 | 후속 통합 작업 필요 |
| 실제 `HandAnchor` 입력 | 미검증 | Apple Vision Pro 필요 |
| 술·인·축 임계값 | 미결정 | 실기기 데이터 필요 |

따라서 이 장의 핵심 결론은 “두 코드를 이미 앱에서 실행했다”가 아니라, **서로 연결할 입력 경계와 실패 정책을 코드와 합성 좌표로 확인했다**는 것이다.

## 전체 데이터 흐름

```text
HandAnchor
→ HandTrackingService
→ HandJointSample(name, originFromJointTransform)
→ translation SIMD3<Float>
→ HandJointWorldPosition
→ HandSample
→ HandFeatureExtractor
→ HandFeatures
```

ARKit과 RealityKit 타입은 추적·표현 계층에 남긴다. Pose Features Package는 표준 Swift와 SIMD 위치만 입력으로 받아 합성 좌표 테스트를 실행할 수 있게 한다.

## 1단계: 월드 transform에서 위치를 꺼낸다

PR #8의 `HandJointSample`에는 4장에서 만든 월드 transform이 저장되어 있다.

```swift
struct HandJointSample {
    let name: HandSkeleton.JointName
    let originFromJointTransform: simd_float4x4
}
```

4×4 transform의 네 번째 열에서 translation을 꺼내면 특징 계산에 필요한 월드 위치가 된다.

```swift
let column = joint.originFromJointTransform.columns.3
let position = SIMD3<Float>(column.x, column.y, column.z)
```

이 위치는 4장에서 Entity에 적용한 좌표와 같은 월드 좌표계에 있어야 한다. 한 손의 일부 관절만 다른 기준 공간이나 단위를 사용하면 거리와 방향 특징의 의미가 깨진다.

## 2단계: ARKit 비의존 입력으로 바꾼다

Pose Features Package는 추적 계층과 특징 계산 계층 사이의 값으로 `HandJointWorldPosition`을 사용한다.

```swift
public struct HandJointWorldPosition: Equatable, Sendable {
    public let joint: HandJoint
    public let position: SIMD3<Float>
}
```

한 손의 좌우 구분, 전체 추적 상태와 관절 위치 배열은 `HandSample` 생성자로 전달한다.

```swift
let sample = try HandSample(
    side: .left,
    isTracked: true,
    jointWorldPositions: jointWorldPositions
)
```

이 생성자는 다음 두 입력을 정상 표본으로 만들지 않는다.

- 손 전체가 추적되지 않음 → `handNotTracked`
- 같은 관절이 두 번 들어옴 → `duplicateJoint`

관절이 일부 빠진 경우에는 임의 위치를 넣지 않고 부분 `HandSample`을 만든다. 이후 실제 특징 계산이 필요한 전체 관절 목록과 비교해 `missingJoints` 오류를 반환한다.

> 현재 앱 타깃에는 PR #8의 `HandSkeleton.JointName`을 Package의 `HandJoint`로 바꾸는 실제 어댑터가 아직 연결되지 않았다. 이 장은 어댑터가 사용할 양쪽 입력 타입과 오류 계약을 설명한다.

## 3단계: 25개 관절 계약을 확인한다

PR #8의 Hand Tracking catalog에는 27개 관절이 있다. 현재 Pose Features는 팔뚝 관절 두 개를 제외한 25개를 사용한다.

```text
PR #8 HandJointCatalog: 27개
− forearmArm
− forearmWrist
= Pose Features HandJoint: 25개
```

손목 1개와 다섯 손가락의 관절이 이름 단위로 대응한다. PR #7의 테스트 `testJointCatalogMatchesTrackingSnapshotContract`가 이 목록을 고정한다.

현재 `HandFeatureExtractor`는 손바닥 크기, 다섯 손가락 특징과 엄지–검지 거리를 한 번에 계산하므로 25개를 모두 요구한다.

```swift
let requiredJoints = Set(HandJoint.allCases)
let missing = requiredJoints.subtracting(sample.joints.keys)

guard missing.isEmpty else {
    throw FeatureExtractionError.missingJoints(Array(missing))
}
```

위 코드는 정책을 이해하기 위한 축약 예시다. 실제 구현은 오류 결과를 재현하기 쉽도록 빠진 관절 이름을 정렬해서 반환한다.

## 왜 누락 관절을 영점으로 채우지 않는가

월드 원점 `(0, 0, 0)`은 “관절이 없음”을 뜻하는 특별한 값이 아니라 실제 공간의 한 위치다. 누락된 손끝을 원점으로 채우면 다음 값들이 모두 실제 손 모양과 무관하게 왜곡된다.

- 손목–손끝 거리
- 손가락 직진도와 굽힘 각도
- 손바닥 크기 정규화 값
- 엄지–검지 끝 거리
- 양손 중심 거리와 방향

계산을 계속하기 위해 데이터를 만드는 것보다 해당 프레임의 특징 계산을 건너뛰는 편이 현재 단계에서는 안전하다.

다만 Apple의 [`Joint.isTracked`](https://developer.apple.com/documentation/arkit/handskeleton/joint/istracked) 문서는 관절이 가려진 경우에도 추정 transform을 제공할 수 있다고 설명한다. 실제 앱에서는 다음 대안을 실기기 데이터로 비교해야 한다.

1. 현재처럼 25개 중 하나라도 빠지면 전체 계산을 건너뛴다.
2. 술·인·축 포즈마다 필요한 관절만 요구한다.
3. 제한된 시간 동안 신뢰 가능한 이전 값이나 ARKit 추정 transform을 사용한다.

이 선택은 이 장에서 확정하지 않는다.

## 4단계: 손 크기를 정규화한다

같은 자세라도 사람마다 손 크기가 다르므로 절대거리 하나만으로 임계값을 만들기 어렵다. 현재 프로토타입은 세 가지 손바닥 크기 후보를 노출한다.

| 후보 | 계산 | 현재 판단 |
| --- | --- | --- |
| 손바닥 너비 | 검지–새끼손가락 metacarpal 거리 | 손가락 벌림과 노이즈 영향을 실기기에서 확인해야 함 |
| 손바닥 길이 | 손목–중지 metacarpal 거리 | 기준선이 짧아 위치 오차 영향을 확인해야 함 |
| 기하평균 | `sqrt(너비 × 길이)` | 합성 좌표의 임시 정규화 기준 |

```swift
let palmWidth = simd_distance(indexMetacarpal, littleMetacarpal)
let palmLength = simd_distance(wrist, middleMetacarpal)
let geometricMean = sqrt(palmWidth * palmLength)
```

합성 좌표에서는 평행이동·회전·균일 스케일 뒤에도 기하평균으로 나눈 거리가 유지됐다. 이것은 실제 사용자 사이에서도 가장 안정적이라는 뜻은 아니다.

## 5단계: 한 손 특징을 계산한다

### 손가락 직진도

첫 관절과 손끝 사이 직선거리를 손가락 뼈 구간의 전체 경로 길이로 나눈다.

```text
straightness = 첫 관절–손끝 직선거리 / 모든 구간 길이의 합
```

값이 1에 가까울수록 관절 경로가 곧다. 합성 검지 좌표에서는 펼친 손 `1.00`, 부분 굽힘 약 `0.86`, 주먹 약 `0.39` 순서였다. 이 값은 테스트 fixture의 관찰값이며 판정 임계값이 아니다.

### 굽힘 각도

연속된 두 뼈 방향 벡터의 내적에 `acos`를 적용한다. 0에 가까울수록 두 구간이 곧게 이어진다.

### 손끝과 핀치 거리

- 손목–각 손끝의 거리
- 엄지 끝–검지 끝의 거리
- 위 거리를 손바닥 기하평균으로 나눈 정규화 거리

합성 핀치 좌표에서는 엄지–검지 정규화 거리가 펼친 손보다 작아지는 것을 확인했다. 실제 포즈 임계값은 아직 정하지 않는다.

## 6단계: 양손 관계를 계산한다

`BimanualFeatureExtractor`는 왼손과 오른손의 `HandSample`에서 다음 값을 계산한다.

- 두 손바닥 중심의 절대거리와 정규화 거리
- 왼손 중심에서 오른손 중심으로 향하는 단위 방향
- 두 손바닥 법선의 정렬도
- 각 손바닥이 상대 손을 향하는 정도

두 손바닥 중심이 정확히 같으면 방향을 정의할 수 없다. 이 경우 0 벡터를 만들지 않고 방향과 마주 보기 점수를 `nil`로 반환해 NaN을 피한다.

> PR #8은 왼손과 오른손 Anchor update를 각각 받는다. 두 snapshot의 시간 차를 얼마까지 허용할지는 아직 구현되지 않았다. 빠르게 움직이는 두 손의 특징을 계산하기 전에 timestamp 동기화 정책이 필요하다.

## 테스트로 확인한 내용

다음 명령은 ARKit이나 Apple Vision Pro 없이 순수 Swift Package 테스트를 실행한다.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun swift test --package-path Spikes/PoseFeatures
```

PR #7 커밋 `9d8dbae` 기준 결과는 **12 tests, 0 failures**다.

- 펼친 손, 부분 굽힘과 주먹의 직진도 순서
- 핀치에서 엄지–검지 정규화 거리 감소
- 평행이동·회전·균일 스케일 뒤 정규화 특징 유지
- 거울 자세의 좌우 손바닥 법선 일관성
- 양손 거리·방향·마주 보기 계산
- NaN·무한대·퇴화한 입력의 명시적 오류
- PR #8 snapshot 형태로 만든 `HandSample`의 동일한 특징값
- 추적 해제·중복·누락 관절 오류 정책

## 확인 방법

### 실기기 없이 확인한 범위

- PR #8의 27개 관절과 Pose Features의 25개 관절 이름을 대조했다.
- snapshot 형태의 합성 입력과 기존 `HandSample`이 같은 특징값을 만드는지 테스트했다.
- 12개 Swift 테스트를 실행해 통과를 확인했다.
- Pose Features Package가 ARKit과 RealityKit을 import하지 않는 구조를 확인했다.

### 아직 연결하지 않은 범위

- PR #8 앱 타깃에서 실제 `HandJointWorldPosition` 배열을 만드는 어댑터
- 앱에서 snapshot을 받아 `HandFeatureExtractor`를 호출하는 종단 간 흐름
- 좌우 Anchor timestamp 차이 처리
- 특징값과 누락 관절을 보여 주는 디버그 UI

### Apple Vision Pro에서 확인할 범위

- 실제 프레임에서 25개 관절을 동시에 확보하는 비율
- 손 가림과 빠른 움직임에서 관절별 추적 손실 빈도
- 실제 좌표의 방향, 단위와 좌우 손바닥 법선
- 사용자별 손 크기에서 정규화 후보의 안정성
- 술·인·축 특징값 범위와 판정 임계값

이 항목들은 이 장의 문서 작성 완료와 별개인 **실기기 미검증 항목**이다.

## 문제 해결

### `missingJoints`가 자주 발생한다

- 관절 이름 매핑에서 `forearmArm`, `forearmWrist`만 제외했는지 확인한다.
- 추적 계층이 `Joint.isTracked == false`인 관절을 제외하고 있는지 확인한다.
- 임시로 영점 좌표를 넣지 말고 어떤 관절이 자주 빠지는지 기록한다.
- 실기기 로그를 확보한 뒤 포즈별 필수 관절 정책을 검토한다.

### 정규화 결과가 NaN 또는 무한대다

- 모든 위치가 유한한지 확인한다.
- 손바닥 너비와 길이가 0에 가까운 퇴화 입력인지 확인한다.
- 길이가 0인 손가락 구간이 있는지 확인한다.

### 좌우 손바닥 법선 방향이 반대로 나온다

- `HandSample.side`가 ARKit chirality와 일치하는지 확인한다.
- 왼손 법선의 부호 보정이 적용되는지 확인한다.
- 실제 손바닥 앞·뒤 의미는 실기기 좌표로 다시 확인한다.

## 다음 단계

이 장 다음 구현에서는 ARKit 어댑터와 디버그 UI를 앱 타깃에 연결해야 한다. 그 뒤 실기기 로그를 수집해 25개 전체 관절 정책과 포즈별 관절 정책을 비교하고, 별도 DECISION에서 정규화 기준과 임계값을 채택한다.

## 이 장의 완료 기준

- Hand Tracking 월드 transform에서 Pose Features 입력을 만드는 경계를 설명할 수 있다.
- 25개 관절 계약과 누락 관절을 영점으로 채우지 않는 이유를 설명할 수 있다.
- 손 크기 정규화, 한 손 특징과 양손 특징의 목적을 설명할 수 있다.
- 합성 좌표 테스트, 코드 수준 호환성, 앱 미연결과 실기기 미검증을 구분할 수 있다.
- 실제 임계값과 추적 손실 정책이 아직 결정되지 않았음을 설명할 수 있다.

[이전: 4장 관절을 공간에 그리기](./04-joint-visualization.md)
