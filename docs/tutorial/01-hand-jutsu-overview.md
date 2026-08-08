# 01. Hand Jutsu 시작하기

> 상태: 초안
> 관련 문서: `docs/PROJECT_FOUNDATION.md`

## 이 장의 목표

이 장에서는 Hand Jutsu가 어떤 프로젝트인지, 1차 튜토리얼이 어디까지 다루는지 정리한다.

학습자는 이 장을 통해 다음을 이해해야 한다.

- Hand Jutsu의 최종 목표
- 1차 튜토리얼에서 다루는 범위
- Apple Vision Pro 실기기가 필요한 부분과 실기기 없이 진행 가능한 부분
- GitHub Issue, PR, Wiki, `docs`를 나누어 사용하는 이유

## 프로젝트 한 문장

Hand Jutsu는 SwiftUI, RealityKit, ARKit을 이용해 Apple Vision Pro에서 양손 Hand Pose를 인식하고, 이후 공간 술법 효과로 확장할 수 있는 visionOS 튜토리얼 프로젝트다.

## 1차 튜토리얼의 기준

1차 튜토리얼은 "손 모양에 따른 완성된 공간 술법 효과"까지 한 번에 구현하지 않는다. 먼저 양손 추적과 관절 좌표 흐름을 이해하고, Pose 판정에 사용할 수 있는 재료를 만드는 데 집중한다.

```text
ImmersiveSpace
→ HandTrackingProvider
→ HandAnchor
→ Joint world transform
→ Pose Features
→ Hand Pose 판정 재료
```

## 실기기 없이 가능한 부분

- Xcode 프로젝트 구조 이해
- SwiftUI Window와 Immersive Space 코드 읽기
- RealityKit Entity 구조 이해
- Pose Features 계산 로직의 순수 Swift 테스트
- 합성 좌표를 사용한 입력 계약 검증
- 튜토리얼 문서 구조 정리

## Apple Vision Pro가 필요한 부분

- 손 추적 권한 프롬프트 확인
- 실제 왼손과 오른손 `HandAnchor` 수신 확인
- 관절 구체가 실제 손 이동과 회전에 맞게 따라오는지 확인
- 손 가림, 빠른 움직임, 추적 손실 상황 확인
- 실제 손 크기와 방향에 따른 Pose Features 값 관찰
- 포즈별 임계값 조정

## GitHub를 작업 공간으로 사용하는 방식

이 프로젝트는 Notion 대신 GitHub를 중심으로 기록한다.

- Issue: 작업 단위, 질문, Spike, 검증 항목을 남긴다.
- PR: 실제 변경 사항과 리뷰 맥락을 남긴다.
- Wiki: 회의, 탐색 일지, 전체 진행 요약을 남긴다.
- `docs`: 튜토리얼 기준 문서와 최종 독자가 읽을 문서를 관리한다.

AI에게 작업을 맡길 때는 Issue와 PR 링크를 함께 전달한다. AI는 링크의 맥락을 읽고 초안, 구현, 리뷰 체크리스트를 도울 수 있지만, 실기기 검증이나 최종 판단은 사람이 확인해야 한다.

## 이 장의 완료 기준

- 프로젝트 목표를 한 문장으로 설명할 수 있다.
- 1차 튜토리얼과 후속 확장의 경계를 구분할 수 있다.
- 실기기 검증이 필요한 항목을 완료된 기능으로 착각하지 않는다.
- GitHub Issue, PR, Wiki, `docs`의 역할을 구분할 수 있다.
