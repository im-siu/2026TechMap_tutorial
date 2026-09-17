# Hand Jutsu 시작하기

Hand Jutsu는 SwiftUI, RealityKit, ARKit을 사용해 Apple Vision Pro에서 양손을 추적하고, 손 모양 판정에 필요한 관절 데이터를 만드는 visionOS 튜토리얼이다.

이 장에서는 빈 프로젝트를 만들고 처음 실행한 뒤, 다음 장부터 어떤 파일을 바꾸게 되는지 확인한다. 아직 Hand Tracking을 켜거나 관절을 그리지는 않는다.

## 이 장을 마치면

- 빈 visionOS App 프로젝트를 만들고 Simulator에서 기본 Window를 실행할 수 있다.
- Simulator와 Apple Vision Pro 실행에서 Signing이 필요한 시점을 구분할 수 있다.
- 기본 생성 파일 중 다음 장에서 바꾸게 될 파일을 찾을 수 있다.

## 작성 환경

이 문서는 아래 환경에서 작성하고 Simulator 빌드 절차를 확인했다. 다른 버전에서도 동작할 수 있지만, 화면과 메뉴 이름이 다르면 이 조합을 먼저 맞춘다.

| 항목 | 사용한 환경 |
| --- | --- |
| Xcode | 27.0 (27A266a) |
| visionOS Simulator runtime | 26.5 |

Apple Vision Pro의 시스템 버전과 실제 Signing Team은 사용하는 기기에 맞춰 Xcode에서 선택한다.

## 1. 빈 visionOS App 만들기

Xcode에서 **File > New > Project**를 선택하고, **visionOS > App** 템플릿을 고른다. 이 템플릿은 기본 Window와 SwiftUI 진입점을 함께 만들어 주므로, 2장에서 Immersive Space를 추가하기 전의 출발점으로 적합하다.

프로젝트 옵션은 아래처럼 설정한다.

| 항목 | 값 | 이유 |
| --- | --- | --- |
| Product Name | `HandJutsu` | 이후 코드와 앱 이름을 같은 이름으로 맞춘다. |
| Organization Identifier | 자신의 역방향 도메인 | Bundle Identifier를 고유하게 만든다. |
| Interface | SwiftUI | 이 튜토리얼의 Window와 상태 UI가 SwiftUI로 작성된다. |
| Language | Swift | 튜토리얼 코드와 같은 언어다. |
| Initial Scene | Window | 앱은 먼저 기본 Window로 시작하고, 2장에서 필요한 때 Immersive Space를 연다. |

## 2. Team과 Signing 확인하기

프로젝트를 만든 뒤 target의 **Signing & Capabilities**에서 Team을 선택한다.

- Simulator만 실행할 때는 Xcode가 선택한 개발 설정으로 기본 Window를 빌드할 수 있다.
- Apple Vision Pro에 설치할 때는 본인의 개발 Team과 고유한 Bundle Identifier가 필요하다.
- 3장에서 Hand Tracking을 추가할 때도 이 target의 **Signing & Capabilities**에서 capability를 추가한다.

Signing 오류가 나면 Product Name을 바꾸기보다 Team과 Bundle Identifier가 현재 계정·기기와 맞는지 먼저 확인한다.

## 3. 기본 생성 파일 둘러보기

생성 직후에는 아래 기본 파일만 먼저 확인한다.

| 파일 | 지금 하는 일 | 다음 장에서의 변화 |
| --- | --- | --- |
| `HandJutsuApp.swift` | 앱의 Window를 시작한다. | 2장에서 Immersive Space를 등록한다. |
| `ContentView.swift` | Window에 처음 보이는 SwiftUI 화면이다. | 2장에서 Space를 여닫는 버튼을 넣고, 3장에서 추적 상태를 보여 준다. |
| `Assets.xcassets` | 앱 아이콘과 색상 같은 리소스를 둔다. | 이번 1–3장에서는 기본값을 유지한다. |

`Info` 탭과 Signing 설정은 파일 탐색기에 항상 보이지 않을 수 있다. 3장의 사용 목적 문구는 target의 **Info** 설정에서 추가한다.

## 4. 첫 Simulator 실행

상단 실행 대상에서 **Apple Vision Pro Simulator**를 고른 뒤 Run을 누른다. 기본 `ContentView`의 인사말이 Window에 보이면, 2장의 출발점이 준비된 것이다.

확인할 항목은 다음과 같다.

- 선택한 Simulator에서 빌드가 끝난다.
- 기본 Window가 열린다.
- `ContentView.swift`를 바꾸면 Window의 텍스트도 바뀐다.

이 화면은 아직 공간 콘텐츠나 손 추적 결과를 보여 주지 않는다. 그것은 각각 2장과 3장에서 추가한다.

## 기기별 확인 범위

Simulator에서는 Window, Immersive Space의 열기·닫기 UI, 순수 Swift 계산을 확인한다. 실제 권한 프롬프트, `HandAnchor`, 관절 움직임은 Apple Vision Pro에서 확인한다.

## 다음 장

다음 장에서는 <doc:02-Creating-Immersive-Space>에서 기본 Window를 유지한 채, 필요할 때만 열리는 Immersive Space를 추가한다.
