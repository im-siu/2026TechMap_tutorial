# Immersive Space 구성하기

Hand Jutsu의 손 추적과 공간 시각화는 `ImmersiveSpace` 안에서 실행된다.

이 장에서는 Hand Tracking을 붙이기 전에 visionOS 앱의 기본 무대를 만든다. 기본 Window에서 버튼을 눌러 Immersive Space를 열고, 다시 닫을 수 있는 구조를 먼저 준비한다.

## Window와 Immersive Space

visionOS 앱은 보통 기본 Window와 Immersive Space가 서로 다른 역할을 맡는다.

Window는 사용자가 앱을 시작하고 상태를 확인하는 기본 화면이다. Hand Jutsu에서는 Immersive Space를 여는 버튼과 간단한 상태 표시를 둘 수 있다.

Immersive Space는 사용자의 주변 공간 위에 3D 콘텐츠를 배치하는 영역이다. 이후 장에서 손 관절을 표시하는 RealityKit Entity와 `ARKitSession`은 이 공간 안에서 연결한다.

이번 장에서는 아직 손 추적을 시작하지 않는다. 먼저 앱이 공간을 열고 닫을 수 있는지 확인한다.

## App 진입점에 공간 선언하기

먼저 앱 진입점에서 기본 Window와 Immersive Space를 함께 선언한다.

```swift
import SwiftUI

@main
struct HandJutsuApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "HandJutsuSpace") {
            ImmersiveView()
        }
    }
}
```

`WindowGroup`은 앱의 기본 창을 만든다. `ImmersiveSpace`는 나중에 열 수 있는 공간을 등록한다.

여기서 중요한 값은 `ImmersiveSpace`의 `id`다. 이 문자열은 Window에서 공간을 열 때 다시 사용한다. 오타를 줄이기 위해 실제 프로젝트에서는 상수로 분리해도 좋다.

```swift
enum AppSpace {
    static let handJutsu = "HandJutsuSpace"
}
```

상수를 사용하면 앱 진입점은 다음처럼 쓸 수 있다.

```swift
@main
struct HandJutsuApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: AppSpace.handJutsu) {
            ImmersiveView()
        }
    }
}
```

## Window에서 공간 열기

Window 화면에서는 SwiftUI 환경 값인 `openImmersiveSpace`를 사용해 Immersive Space를 연다.

```swift
import SwiftUI

struct ContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var isImmersiveSpaceOpen = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Hand Jutsu")
                .font(.largeTitle)

            Button(isImmersiveSpaceOpen ? "Close Space" : "Open Space") {
                Task {
                    if isImmersiveSpaceOpen {
                        await dismissImmersiveSpace()
                        isImmersiveSpaceOpen = false
                    } else {
                        let result = await openImmersiveSpace(id: AppSpace.handJutsu)

                        if case .opened = result {
                            isImmersiveSpaceOpen = true
                        }
                    }
                }
            }
        }
        .padding()
    }
}
```

`openImmersiveSpace`는 비동기 작업이다. 그래서 버튼 안에서 `Task`를 만들고 `await`로 결과를 기다린다.

결과가 `.opened`일 때만 `isImmersiveSpaceOpen`을 `true`로 바꾼다. 사용자가 공간 열기를 취소하거나 시스템이 요청을 처리하지 못한 경우까지 열린 상태로 표시하지 않기 위해서다.

## Immersive View 준비하기

이제 Immersive Space 안에 들어갈 View를 만든다.

```swift
import RealityKit
import SwiftUI

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            let root = Entity()
            root.name = "HandJutsuRoot"
            content.add(root)
        }
    }
}
```

이번 장의 `ImmersiveView`는 비어 있는 root entity만 추가한다.

이 root entity는 이후 장에서 손 관절 구체나 공간 효과를 붙일 기준점이 된다. 처음부터 손 추적, 포즈 판정, 효과 연출을 모두 넣지 않고 공간의 시작점을 분리해 두면 다음 단계의 책임이 더 분명해진다.

## Simulator에서 확인하기

이번 장은 Apple Vision Pro 실기기가 없어도 확인할 수 있다.

Simulator에서는 다음을 확인한다.

- 앱이 기본 Window로 실행되는지
- 버튼을 눌렀을 때 Immersive Space 요청이 동작하는지
- 공간을 닫는 버튼 상태가 자연스럽게 바뀌는지
- `ImmersiveView`가 RealityKit content를 만들 수 있는지

실제 손 입력은 아직 사용하지 않으므로, Hand Tracking 권한이나 손 관절 데이터는 확인하지 않는다.

## 다음 장으로 이어가기

이 장에서 만든 구조는 다음 장의 출발점이다.

3장에서는 `ImmersiveView`가 열렸을 때 `ARKitSession`과 `HandTrackingProvider`를 시작하고, 왼손과 오른손 `HandAnchor`를 받는 흐름을 연결한다.

Window는 앱 상태를 보여 주는 화면으로 남겨 두고, Immersive Space는 손 추적과 RealityKit 시각화가 실행되는 공간으로 확장한다.

## 이 장의 완료 기준

이 장을 마치면 다음을 설명할 수 있어야 한다.

- `WindowGroup`과 `ImmersiveSpace`의 역할 차이
- 앱 진입점에서 Immersive Space를 등록하는 방법
- Window에서 `openImmersiveSpace`와 `dismissImmersiveSpace`를 호출하는 흐름
- `ImmersiveView`가 이후 ARKit과 RealityKit 코드의 시작점이 되는 이유
