# 01. Hand Jutsu 시작하기

> 상태: 초안
> 관련 문서: `docs/PROJECT_FOUNDATION.md`

## 이 장의 목표

이 장에서는 Hand Jutsu가 어떤 프로젝트인지, 튜토리얼을 끝내면 무엇을 이해할 수 있는지 정리한다.

학습자는 이 장을 통해 다음을 이해해야 한다.

- Hand Jutsu에서 만들 결과물
- 튜토리얼을 따라가기 전에 필요한 사전 지식
- 전체 학습 흐름
- Apple Vision Pro 실기기에서 확인해야 하는 부분

## Hand Jutsu란?

Hand Jutsu는 SwiftUI, RealityKit, ARKit을 이용해 Apple Vision Pro에서 양손을 추적하고, 손 모양 판정에 필요한 관절 데이터를 만드는 visionOS 튜토리얼이다.

이 튜토리얼에서는 먼저 손을 공간 안의 데이터로 이해하는 데 집중한다. 완성된 공간 효과보다 아래 흐름을 차근차근 따라간다.

```text
Immersive Space 열기
→ 양손 Hand Tracking 시작하기
→ 손 관절의 월드 좌표 계산하기
→ 관절 위치를 공간에 시각화하기
→ Pose Features 입력으로 연결하기
```

## 이 튜토리얼에서 만들 것

최종 결과물은 양손의 추적 상태를 확인하고, 손 관절을 공간에 표시한 뒤, 손 모양 판정에 사용할 수 있는 입력 데이터를 정리하는 기초 앱이다.

튜토리얼을 마치면 다음을 설명할 수 있어야 한다.

```text
ImmersiveSpace
→ HandTrackingProvider
→ HandAnchor
→ Joint world transform
→ Pose Features
→ Hand Pose 판정 재료
```

이 단계에서는 포즈 이름을 안정적으로 확정하거나 화려한 술법 효과를 완성하는 것보다, Hand Tracking 데이터가 어떤 형태로 들어오고 다음 계산 단계로 어떻게 이어지는지 이해하는 것을 우선한다.

## 필요한 사전 지식

아래 내용을 알고 있으면 튜토리얼을 따라가기 쉽다.

- SwiftUI로 간단한 화면을 만들어 본 경험
- Xcode에서 visionOS 앱 프로젝트를 열고 실행하는 기본 흐름
- Swift의 구조체, 열거형, 옵셔널 사용법
- `async` / `await` 코드를 읽을 수 있는 정도의 비동기 이해

RealityKit, ARKit, 3D 좌표 변환, Hand Tracking은 처음 접해도 된다. 필요한 개념은 튜토리얼 흐름 안에서 필요한 만큼만 다룬다.

## 학습 흐름

| 장 | 제목 | 목표 |
| --- | --- | --- |
| 1 | Hand Jutsu 시작하기 | 만들 결과물, 사전 지식, 검증 범위 이해 |
| 2 | 첫 Immersive Space | Window와 Immersive Space의 역할 이해 |
| 3 | 양손 추적 시작 | `HandTrackingProvider`와 `ARKitSession` 생명주기 이해 |
| 4 | 관절을 공간에 그리기 | Hand Anchor와 Joint transform으로 관절 위치 표시 |
| 5 | Pose Features로 이어가기 | 관절 월드 좌표를 손 모양 판정 재료로 변환 |

## 실기기 없이 따라갈 수 있는 부분

- Xcode 프로젝트 구조 이해
- SwiftUI Window와 Immersive Space 코드 읽기
- RealityKit Entity 구조 이해
- Pose Features 계산 로직의 순수 Swift 테스트
- 합성 좌표를 사용한 입력 계약 검증

## Apple Vision Pro에서 확인해야 하는 부분

- 손 추적 권한 프롬프트 확인
- 실제 왼손과 오른손 `HandAnchor` 수신 확인
- 관절 구체가 실제 손 이동과 회전에 맞게 따라오는지 확인
- 손 가림, 빠른 움직임, 추적 손실 상황 확인
- 실제 손 크기와 방향에 따른 Pose Features 값 관찰
- 포즈별 임계값 조정

## 이번 튜토리얼에서 다루지 않는 것

이 튜토리얼은 손 추적과 포즈 판정의 재료를 만드는 데 집중한다. 아래 내용은 이후 심화 단계에서 다룬다.

- 손 떨림과 오인식을 줄이는 smoothing
- 포즈가 일정 시간 유지되었는지 확인하는 상태 처리
- 준비, 충전, 발동, 쿨다운 같은 술법 상태 머신
- 손 모양에 반응하는 완성형 공간 효과

먼저 작은 단계에서 손 관절을 안정적으로 읽고 해석할 수 있어야, 이후 효과와 상태 전환도 설명 가능한 코드로 확장할 수 있다.

## 이 장의 완료 기준

- 프로젝트 목표를 한 문장으로 설명할 수 있다.
- 튜토리얼에서 만들 결과물을 설명할 수 있다.
- 실기기 없이 따라갈 수 있는 부분과 Apple Vision Pro에서 확인해야 하는 부분을 구분할 수 있다.
- 실기기 검증이 필요한 항목을 완료된 기능으로 착각하지 않는다.

## 다음 장

[02. 첫 Immersive Space](./02-first-immersive-space.md)에서는 visionOS 앱에서 Window와 Immersive Space가 어떤 역할을 하는지 살펴본다.
