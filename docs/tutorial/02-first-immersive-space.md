# 02. 첫 Immersive Space

> 상태: 초안
> 기준 코드: PR #8 `d3b57bd5e59e2bf4b62ed57ba02b3aa53d23137f`

## 이 장의 목표

이 장에서는 visionOS 앱에서 Window와 Immersive Space가 어떤 역할을 하는지 살펴보고, 버튼을 눌러 Immersive Space를 열고 닫는 최소 흐름을 이해한다.

학습자는 이 장을 통해 다음을 설명할 수 있어야 한다.

- `WindowGroup`과 `ImmersiveSpace`의 역할 차이
- `AppModel`이 Immersive Space의 ID와 상태를 관리하는 이유
- `openImmersiveSpace(id:)`와 `dismissImmersiveSpace()` 호출 흐름
- Simulator에서 확인할 수 있는 것과 Apple Vision Pro 실기기에서 확인해야 하는 것

## Window와 Immersive Space

visionOS 앱은 일반적인 창 UI와 공간 안에 배치되는 몰입형 UI를 함께 사용할 수 있다.

Hand Jutsu에서는 창 UI를 시작점으로 사용한다. 창에는 프로젝트 이름, Hand Tracking 상태, Immersive Space를 여는 버튼이 표시된다. Immersive Space는 손 관절을 공간에 그리기 위한 RealityKit 장면을 담는다.

```text
WindowGroup
→ ContentView
→ ToggleImmersiveSpaceButton
→ openImmersiveSpace
→ ImmersiveSpace
→ ImmersiveView
```

이 장에서는 아직 Hand Tracking 자체를 깊게 다루지 않는다. 먼저 공간을 열고 닫는 앱의 입구를 만든 뒤, 다음 장에서 `HandTrackingProvider`를 연결한다.

## 앱의 Scene 구조

기준 코드의 `HandJutsuApp`은 두 개의 Scene을 가진다.

```swift
WindowGroup {
    ContentView()
        .environment(appModel)
}

ImmersiveSpace(id: appModel.immersiveSpaceID) {
    ImmersiveView()
        .environment(appModel)
        .onAppear {
            appModel.immersiveSpaceState = .open
        }
        .onDisappear {
            appModel.immersiveSpaceState = .closed
        }
}
```

`WindowGroup`은 사용자가 처음 보는 창을 만든다. 이 창 안의 `ContentView`에서 Immersive Space를 여는 버튼을 제공한다.

`ImmersiveSpace`는 공간 장면의 진입점이다. `id`는 나중에 `openImmersiveSpace(id:)`를 호출할 때 같은 값으로 사용된다.

`onAppear`와 `onDisappear`에서는 Immersive Space가 실제로 열리거나 닫힌 시점에 상태를 갱신한다. 버튼을 누른 순간이 아니라 Scene의 생명주기 이벤트를 기준으로 상태를 확정하는 것이 중요하다.

## AppModel이 관리하는 상태

`AppModel`은 앱 전체에서 공유해야 하는 상태를 담는다.

```swift
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    let handTracking = HandTrackingService()

    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }

    var immersiveSpaceState = ImmersiveSpaceState.closed
}
```

`immersiveSpaceID`는 `ImmersiveSpace` 선언과 열기 요청을 연결하는 문자열이다. 두 값이 다르면 버튼을 눌러도 원하는 Immersive Space를 열 수 없다.

`ImmersiveSpaceState`는 세 가지 상태를 가진다.

| 상태 | 의미 |
| --- | --- |
| `closed` | Immersive Space가 닫혀 있다. |
| `inTransition` | 열기 또는 닫기 요청이 진행 중이다. |
| `open` | Immersive Space가 열려 있다. |

`inTransition` 상태를 따로 두면 열기/닫기 요청이 진행되는 동안 버튼을 다시 누르는 상황을 막을 수 있다.

## 열기와 닫기 버튼 흐름

`ToggleImmersiveSpaceButton`은 현재 상태에 따라 Immersive Space를 열거나 닫는다.

```swift
switch appModel.immersiveSpaceState {
case .open:
    appModel.immersiveSpaceState = .inTransition
    await dismissImmersiveSpace()

case .closed:
    appModel.immersiveSpaceState = .inTransition
    switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
    case .opened:
        break
    case .userCancelled, .error:
        fallthrough
    @unknown default:
        appModel.immersiveSpaceState = .closed
    }

case .inTransition:
    break
}
```

닫을 때는 `dismissImmersiveSpace()`를 호출한다. 이때 버튼 코드에서 바로 `closed`로 확정하지 않고, `ImmersiveView.onDisappear()`에서 닫힘 상태를 반영한다.

열 때는 `openImmersiveSpace(id:)`를 호출한다. 열기에 성공하면 `ImmersiveView.onAppear()`에서 `open` 상태가 된다. 사용자가 취소하거나 오류가 발생하면 다시 `closed` 상태로 돌린다.

이 흐름은 비동기 작업이다. 그래서 버튼 액션 안에서 `Task`를 사용하고, 열기/닫기 중에는 버튼을 비활성화한다.

```swift
.disabled(appModel.immersiveSpaceState == .inTransition)
```

## ImmersiveView에서 준비하는 것

`ImmersiveView`는 RealityKit 장면을 만들고, 공간 안에서 사용할 root entity를 추가한다.

```swift
RealityView { content in
    content.add(visualizer.rootEntity)
    appModel.handTracking.onSnapshotChanged = { snapshot in
        visualizer.apply(snapshot)
    }
    appModel.handTracking.start()
}
.onDisappear {
    appModel.handTracking.stop()
    appModel.handTracking.onSnapshotChanged = nil
}
```

이 장에서는 Immersive Space 생명주기를 이해하는 것이 목표다. `handTracking.start()`의 내부 동작과 관절 시각화는 다음 장과 4장에서 나누어 다룬다.

여기서 중요한 점은 Immersive Space가 열릴 때 공간 장면에 필요한 준비를 하고, 닫힐 때 사용 중인 작업을 정리한다는 것이다.

## Simulator에서 확인할 수 있는 것

이 장의 범위에서는 Simulator로 다음을 확인할 수 있다.

- 창 UI가 표시되는지
- 버튼을 눌렀을 때 Immersive Space 열기 흐름이 시작되는지
- 열기/닫기 중 버튼 상태가 바뀌는지
- RealityKit 장면 진입점이 구성되어 있는지

Simulator에서 이 흐름을 확인하더라도 실제 손 입력이 검증된 것은 아니다. Simulator는 공간을 여는 앱 구조를 확인하는 데 유용하지만, 실제 Hand Tracking 품질을 판단하는 기준은 될 수 없다.

## Apple Vision Pro에서 확인해야 하는 것

Apple Vision Pro 실기기에서는 다음을 별도로 확인해야 한다.

- Immersive Space 전환이 실제 기기에서 자연스럽게 이루어지는지
- 손 추적 권한 프롬프트가 기대한 시점에 표시되는지
- Immersive Space가 닫힐 때 Hand Tracking 작업이 정리되는지
- 실제 손 입력이 다음 장의 Hand Tracking 흐름으로 이어지는지

이 장의 성공 기준은 손 추적 자체가 아니라, Hand Tracking을 시작할 수 있는 공간 앱 구조를 이해하는 것이다.

## 이 장의 완료 기준

- `WindowGroup`과 `ImmersiveSpace`의 역할을 구분할 수 있다.
- `AppModel`의 `immersiveSpaceID`와 `immersiveSpaceState`가 왜 필요한지 설명할 수 있다.
- `openImmersiveSpace(id:)`와 `dismissImmersiveSpace()`의 호출 흐름을 설명할 수 있다.
- Simulator에서 확인 가능한 범위와 Apple Vision Pro 실기기 검증이 필요한 범위를 구분할 수 있다.

## 이전 장 / 다음 장

- 이전: [01. Hand Jutsu 시작하기](./01-hand-jutsu-overview.md)
- 다음: [03. 양손 추적 시작](./03-hand-tracking-start.md)
