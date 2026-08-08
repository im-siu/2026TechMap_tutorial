# 02. Hand Tracking 흐름

> 상태: 초안
> 관련 이슈/PR: #5, #8

## 이 장의 목표

이 장에서는 ARKit의 `HandTrackingProvider`로 양손을 추적하고, RealityKit에서 관절을 시각화하기까지의 코드 흐름을 정리한다.

학습자는 이 장을 통해 다음을 이해해야 한다.

- `ARKitSession`과 `HandTrackingProvider`의 역할
- 왼손과 오른손 `HandAnchor`를 구분하는 방법
- 추적되지 않은 손과 누락된 관절을 다루는 방법
- Hand Anchor와 Joint transform을 이용해 관절의 월드 transform을 계산하는 흐름
- 시각화 책임을 별도 객체로 분리하는 이유

## 현재 Spike 코드의 책임 분리

PR #8의 Hand Tracking Spike는 본편 코드로 이어갈 수 있도록 역할을 나누어 둔다.

| 구성 요소 | 책임 |
| --- | --- |
| `ContentView` | 앱 창에서 상태와 좌우 손 관절 수를 표시한다. |
| `ImmersiveView` | RealityKit 장면에 시각화 root entity를 붙이고 Hand Tracking 생명주기를 시작한다. |
| `HandTrackingService` | `ARKitSession`, `HandTrackingProvider`, anchor updates, 추적 상태를 관리한다. |
| `HandTrackingSnapshot` | 현재 프레임의 왼손/오른손 추적 결과를 UI와 시각화 계층에 전달한다. |
| `HandJointVisualizer` | 관절 위치를 RealityKit 구체로 표현한다. |

이 구조의 의도는 ARKit 입력, 중간 데이터, RealityKit 시각화, SwiftUI 상태 표시를 한 파일에 섞지 않는 것이다.

## 데이터 흐름

현재 Hand Tracking 흐름은 다음 순서로 볼 수 있다.

```text
HandTrackingProvider.anchorUpdates
→ HandAnchor
→ chirality로 왼손/오른손 구분
→ handSkeleton과 추적 상태 확인
→ Joint별 world transform 계산
→ HandTrackingSnapshot 갱신
→ HandJointVisualizer가 RealityKit Entity 위치 갱신
```

## 관절 월드 transform 계산

Hand Anchor의 관절 위치를 공간에 그리려면 anchor 기준 transform을 월드 기준 transform으로 바꾸어야 한다.

현재 Spike에서는 다음 흐름을 사용한다.

```text
originFromAnchorTransform * anchorFromJointTransform
```

이 계산 결과를 관절의 월드 transform으로 보고, RealityKit 구체의 위치 갱신에 사용한다.

## 추적 손실 처리

현재 정책은 보수적으로 잡는다.

- `HandAnchor.isTracked == false`이면 해당 손은 추적되지 않은 상태로 전달한다.
- `handSkeleton`이 없으면 관절 데이터를 만들지 않는다.
- 개별 `Joint.isTracked == false`인 관절은 결과 배열에서 제외한다.
- 누락된 관절을 임의 좌표나 영점 좌표로 채우지 않는다.

이 정책은 튜토리얼에서 중요하다. 실제로 존재하지 않는 관절 데이터를 만들어 넣으면 Pose 판정 단계에서 잘못된 특징값이 계산될 수 있기 때문이다.

## 현재 검증된 내용

- generic visionOS 빌드 통과
- Apple Vision Pro visionOS Simulator 빌드 통과로 보고됨
- 좌우 손과 관절 데이터를 나누는 코드 구조 확인
- 추적되지 않은 손과 누락 관절을 임의 좌표로 대체하지 않는 정책 확인

## 아직 검증하지 못한 내용

- Apple Vision Pro 실기기에서 손 추적 권한 프롬프트가 정상적으로 표시되는지
- 실제 왼손/오른손 `HandAnchor`가 안정적으로 들어오는지
- 관절 구체가 실제 손 이동과 회전에 맞게 따라오는지
- 손 가림과 빠른 움직임에서 추적 손실이 어떻게 나타나는지
- 좌표 변환 결과가 실제 공간에서 기대 위치에 표시되는지

## 이 장의 완료 기준

- Hand Tracking 입력이 어떤 단계로 앱 상태와 RealityKit 시각화에 전달되는지 설명할 수 있다.
- 추적되지 않은 손과 누락 관절을 왜 조심해서 다루어야 하는지 설명할 수 있다.
- 실기기 검증 전 확인된 것과 확인되지 않은 것을 구분할 수 있다.
