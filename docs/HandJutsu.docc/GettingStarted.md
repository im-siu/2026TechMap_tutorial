# Hand Jutsu 시작하기

Hand Jutsu는 SwiftUI, RealityKit, ARKit을 사용해 Apple Vision Pro에서 양손을 추적하고, 손 모양 판정에 필요한 관절 데이터를 만드는 visionOS 튜토리얼이다.

이 장에서는 앞으로 만들 결과물과 필요한 준비물, Simulator에서 확인할 수 있는 부분과 Apple Vision Pro에서 확인해야 하는 부분을 먼저 정리한다.

## 튜토리얼에서 만들 것

이 튜토리얼의 목표는 손을 단순한 입력 장치가 아니라 공간 안의 데이터로 이해하는 것이다.

최종 결과물은 Immersive Space 안에서 양손 추적 상태를 확인하고, 손 관절 위치를 공간에 표시한 뒤, 손 모양 판정에 사용할 수 있는 입력 데이터를 정리하는 기초 앱이다.

1차 튜토리얼은 완성된 공간 효과보다 다음 흐름을 이해하는 데 집중한다.

- Immersive Space 열기
- 양손 Hand Tracking 시작하기
- 손 관절의 월드 좌표 계산하기
- 관절 위치를 공간에 시각화하기
- Pose Features 입력으로 연결하기
- Hand Pose 판정에 필요한 근거 이해하기

## 필요한 준비물

아래 내용을 알고 있으면 튜토리얼을 따라가기 쉽다.

- SwiftUI로 간단한 화면을 만들어 본 경험
- Xcode에서 visionOS 앱 프로젝트를 열고 실행하는 기본 흐름
- Swift의 구조체, 열거형, 옵셔널 사용법
- `async`와 `await` 코드를 읽을 수 있는 정도의 비동기 이해

RealityKit, ARKit, 3D 좌표 변환과 Hand Tracking은 처음 접해도 된다. 필요한 개념은 각 장에서 사용하는 만큼만 설명한다.

## 기기별 확인 범위

이 튜토리얼의 일부 내용은 Simulator에서도 이해하거나 확인할 수 있지만, 실제 손 입력은 Apple Vision Pro에서 확인해야 한다.

Simulator에서 확인할 수 있는 범위는 다음과 같다.

- Xcode 프로젝트 구조 이해
- SwiftUI Window와 Immersive Space 코드 읽기
- RealityKit Entity 구조 이해
- Pose Features 계산 로직의 순수 Swift 테스트
- 합성 좌표를 사용한 입력 계약 검증

Apple Vision Pro에서 확인해야 하는 범위는 다음과 같다.

- 손 추적 권한 프롬프트
- 실제 왼손과 오른손 `HandAnchor` 수신
- 관절 표시가 실제 손 이동과 회전에 맞게 따라오는지 여부
- 손 가림, 빠른 움직임과 추적 손실 상황
- 실제 손 크기와 방향에 따른 Pose Features 값
- 포즈별 임계값 조정

## 학습 흐름

이 튜토리얼은 다섯 장으로 진행한다.

1장에서는 프로젝트 목표와 준비물을 확인한다.

2장에서는 visionOS 앱에서 Window와 Immersive Space가 어떤 역할을 나누는지 살펴본다.

3장에서는 `ARKitSession`과 `HandTrackingProvider`를 사용해 양손 추적을 시작한다.

4장에서는 `HandAnchor`와 Joint transform을 이용해 관절 위치를 공간에 그린다.

5장에서는 관절 월드 좌표를 Pose Features 입력으로 바꾸고, Hand Pose 판정에 필요한 근거를 만든다.

## 이번 튜토리얼에서 다루지 않는 것

1차 튜토리얼은 양손 Hand Pose를 판정할 수 있는 기초 데이터 흐름에 집중한다. 아래 내용은 이후 심화 단계에서 다룬다.

- 손 떨림과 오인식을 줄이는 smoothing
- 포즈가 일정 시간 유지되었는지 확인하는 상태 처리
- 준비, 충전, 발동, 쿨다운 같은 술법 상태 머신
- 손 모양에 반응하는 완성형 공간 효과

먼저 작은 단계에서 손 관절을 안정적으로 읽고 해석할 수 있어야, 이후 효과와 상태 전환도 설명 가능한 코드로 확장할 수 있다.

## 이 장의 완료 기준

이 장을 마치면 다음을 설명할 수 있어야 한다.

- Hand Jutsu의 목표
- 튜토리얼에서 만들 결과물
- Simulator에서 확인할 수 있는 범위
- Apple Vision Pro에서 확인해야 하는 범위
- 2장부터 5장까지 이어지는 학습 흐름

다음 장에서는 <doc:02-Creating-Immersive-Space>에서 Window와 Immersive Space를 구성한다. 이어서 <doc:03-Starting-Hand-Tracking>에서 양손 추적 입력을 시작하고, <doc:04-Visualizing-Hand-Joints>에서 관절 위치를 공간에 그린 뒤, <doc:05-Building-Pose-Features>에서 위치 데이터를 Pose Features 입력으로 바꾼다.
