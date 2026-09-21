# 02. 첫 Immersive Space

이전: [1장 Hand Jutsu 시작하기](./01-hand-jutsu-overview.md) · 다음: [3장 양손 Hand Tracking 시작하기](./03-starting-hand-tracking.md)

이 장에서는 1장에서 만든 기본 Window를 유지하면서, 버튼을 눌렀을 때만 열리는 Immersive Space를 만든다.

## 현재 상태와 목표

기본 visionOS App은 `HandJutsuApp.swift`의 `WindowGroup`으로 시작한다. 손 추적과 3D 콘텐츠는 별도 공간에서 다루므로, 이 장에서는 기본 Window와 Immersive Space의 역할을 분리한다.

## 파일 변경 순서

1. 새 `AppSpace.swift` 파일에 Space id를 만든다.
2. 기본 생성 `HandJutsuApp.swift`를 교체해 `ImmersiveSpace`를 등록한다.
3. 기본 생성 `ContentView.swift`를 교체해 Open/Close 버튼을 넣는다.
4. 새 `ImmersiveView.swift` 파일에 빈 RealityKit root entity를 만든다.

`ImmersiveSpace`를 App에 등록해도 자동으로 열리지는 않는다. 앱은 계속 `ContentView`를 담은 `WindowGroup`으로 시작하며, `openImmersiveSpace(id:)`가 같은 id를 요청할 때 `ImmersiveView`를 담은 Space가 열린다.

## Simulator에서 확인하기

- 처음에는 기본 Window와 `Open Space` 버튼이 보인다.
- 버튼을 누르면 `Close Space` 상태가 되고 Immersive Space가 열린다.
- `Close Space`를 누르면 기본 Window 흐름으로 돌아온다.

이 확인 단계에서는 코드를 더 수정하지 않는다. 빈 `ImmersiveView`는 아직 별도 3D 콘텐츠를 보여 주지 않는다. 손 추적은 다음 장에서 추가한다.

상세 코드와 단계별 설명은 [DocC 2장](../HandJutsu.docc/Tutorials/HandJutsu/02-Creating-Immersive-Space.tutorial)에서 확인한다.

이전: [1장 Hand Jutsu 시작하기](./01-hand-jutsu-overview.md) · 다음: [3장 양손 Hand Tracking 시작하기](./03-starting-hand-tracking.md)
