# 03. 양손 Hand Tracking 시작하기

이전: [2장 첫 Immersive Space](./02-creating-immersive-space.md) · 다음: [4장 관절을 공간에 그리기](./04-joint-visualization.md)

이 장에서는 열린 Immersive Space 안에서 권한을 확인하고 `ARKitSession`과 `HandTrackingProvider`를 시작한다.

## 역할 나누기

- `ARKitSession`: ARKit Provider를 실행한다.
- `HandTrackingProvider`: 손 Anchor 업데이트를 전달한다.
- `HandAnchor`: 왼손 또는 오른손의 현재 추적 정보다.
- `HandTrackingSnapshot`: UI에 보여 줄 좌우 손 상태다.
- `HandTrackingService`: 권한, Session, Provider, Snapshot 갱신을 관리한다.

## 권한과 실행 순서

1. target의 **Signing & Capabilities**에 Hand Tracking capability를 추가한다.
2. target **Info**에 `NSHandsTrackingUsageDescription`을 추가한다.
3. `queryAuthorization(for:)`으로 현재 권한을 읽는다.
4. 아직 결정되지 않았을 때만 `requestAuthorization(for:)`을 호출한다.
5. 권한이 허용된 경우에만 `session.run([provider])`을 실행한다.
6. 거부·지원하지 않음·실패 상태는 Window에 이유를 표시한다.

## 기기별 확인

Simulator에서는 Space를 열었을 때 Window의 상태 UI와 코드 흐름을 확인한다. 실제 Hand Anchor 입력은 Simulator에서 제공하지 않는다.

Apple Vision Pro에서는 권한 요청, 권한 거부 메시지, 권한 허용 뒤 좌우 손 상태, 손을 내렸을 때 `not tracked` 상태 변화를 확인한다.

상세 코드와 단계별 설명은 [DocC 3장](../HandJutsu.docc/Tutorials/HandJutsu/03-Starting-Hand-Tracking.tutorial)에서 확인한다.

이전: [2장 첫 Immersive Space](./02-creating-immersive-space.md) · 다음: [4장 관절을 공간에 그리기](./04-joint-visualization.md)
