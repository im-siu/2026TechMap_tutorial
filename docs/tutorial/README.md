# Hand Jutsu 1차 튜토리얼 초안

> 상태: 초안
> 관련 이슈: #9

이 폴더는 Hand Jutsu 1차 튜토리얼의 문서 구조를 잡기 위한 공간이다. 현재 목표는 완성된 교재를 한 번에 만드는 것이 아니라, 8월 14일까지 팀이 함께 검토할 수 있는 본편 흐름과 검증 상태를 정리하는 것이다.

## 튜토리얼 목표

Hand Jutsu는 SwiftUI, RealityKit, ARKit을 사용해 Apple Vision Pro에서 양손 Hand Pose를 인식하고, 이후 공간 술법 효과로 확장할 수 있는 기초 튜토리얼이다.

1차 튜토리얼은 화려한 공간 효과보다 다음 흐름을 이해하는 데 집중한다.

```text
Immersive Space 열기
→ 손 추적 권한과 세션 시작
→ 양손 HandAnchor 수집
→ 관절의 월드 좌표 계산
→ Pose Features 입력으로 변환
→ 손 모양 판정 재료 이해
```

## 대상 독자

- SwiftUI 기본 문법과 Xcode 프로젝트 생성 경험이 있는 사람
- Swift의 구조체, 열거형, 옵셔널과 기본 비동기 코드를 읽을 수 있는 사람
- RealityKit, ARKit, 3D 좌표 변환과 Hand Tracking은 처음 접해도 되는 사람
- Apple Vision Pro가 없어도 프로젝트 구조와 Pose 판정 로직 일부를 따라가고 싶은 사람

## 1차 튜토리얼 범위

| 장 | 제목 | 목표 | 검증 상태 |
| --- | --- | --- | --- |
| 1 | Hand Jutsu 시작하기 | 프로젝트 목표와 visionOS 앱 구조 이해 | 문서 초안 |
| 2 | 첫 Immersive Space | Window와 Immersive Space의 역할 이해 | Simulator 검증 가능 |
| 3 | 양손 추적 시작 | `HandTrackingProvider`와 `ARKitSession` 생명주기 이해 | 실기기 검증 필요 |
| 4 | 관절을 공간에 그리기 | Hand Anchor와 Joint transform으로 관절 위치 표시 | 실기기 검증 필요 |
| 5 | Pose Features로 이어가기 | 관절 월드 좌표를 손 모양 판정 재료로 변환 | 합성 좌표 검증, 실기기 검증 필요 |

## 현재 문서 구조

현재 `docs/tutorial/`에는 1차 튜토리얼 제작을 위한 묶음 초안과 장별 본문 초안이 함께 있다. 장별 이슈가 진행되면서 최종 `01`-`05` 구조로 순차 전환한다.

| 현재 문서 | 포괄하는 최종 장 |
| --- | --- |
| `01-hand-jutsu-overview.md` | 1장 Hand Jutsu 시작하기 |
| `02-hand-tracking-flow.md` | 2장 첫 Immersive Space, 3장 양손 추적 시작과 4장의 배경 초안 |
| `03-pose-features-bridge.md` | 5장 Pose Features로 이어가기 |
| `04-joint-visualization.md` | 4장 관절을 공간에 그리기 장별 본문 초안 |

최종 튜토리얼 본문 작성 단계에서는 필요에 따라 `01`-`05` 구조로 분리한다.

## 후속 확장으로 분리할 내용

이번 1차 튜토리얼에서는 아래 내용은 본편 완료 조건으로 다루지 않는다.

- 오인식 줄이기: smoothing, 히스테리시스, 자세 유지 시간
- 술법 상태 머신: 준비, 충전, 발동, 쿨다운
- 완성된 공간 효과: 에너지 구체, 방어막, 번개 등
- DocC와 GitHub Pages 배포 자동화

## 문서 목록

- [01. Hand Jutsu 시작하기](./01-hand-jutsu-overview.md)
- [02. Hand Tracking 흐름](./02-hand-tracking-flow.md)
- [03. Pose Features 연결 흐름](./03-pose-features-bridge.md)
- [04. 관절을 공간에 그리기](./04-joint-visualization.md)

## 검증 상태를 쓰는 규칙

- 빌드 통과, Simulator 실행, Apple Vision Pro 실기기 검증을 구분해서 쓴다.
- 실기기에서 확인하지 않은 동작은 완료된 기능처럼 표현하지 않는다.
- 합성 좌표 테스트로 확인한 내용과 실제 `HandAnchor` 입력으로 확인해야 할 내용을 분리한다.
- Issue와 PR 댓글에서 확인된 내용은 문서에 반영하되, 확정되지 않은 판단은 주의사항으로 남긴다.
