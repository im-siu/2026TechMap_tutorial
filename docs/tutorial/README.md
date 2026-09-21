# Hand Jutsu 튜토리얼 Markdown 안내

이 폴더는 DocC 튜토리얼과 같은 1~5장 학습 순서를 Markdown으로 안내한다. 각 장에는 학습자가 수행할 행동과 기기별 확인 범위를 적는다.

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

## 학습 순서

| 장 | 제목 | 목표 | 확인 환경 |
| --- | --- | --- | --- |
| 1 | Hand Jutsu 시작하기 | 빈 프로젝트와 기본 Window 시작 | Simulator |
| 2 | 첫 Immersive Space | Window와 Immersive Space 역할 구분 | Simulator |
| 3 | 양손 추적 시작 | 권한과 `ARKitSession` 생명주기 이해 | Simulator UI, Apple Vision Pro 손 입력 |
| 4 | 관절을 공간에 그리기 | Hand Anchor와 Joint transform으로 관절 위치 표시 | Apple Vision Pro |
| 5 | Pose Features로 이어가기 | 관절 월드 좌표를 손 모양 판정 재료로 변환 | 순수 Swift 테스트, Apple Vision Pro 비교 |

## 후속 확장으로 분리할 내용

이번 1차 튜토리얼에서는 아래 내용은 본편 완료 조건으로 다루지 않는다.

- 오인식 줄이기: smoothing, 히스테리시스, 자세 유지 시간
- 술법 상태 머신: 준비, 충전, 발동, 쿨다운
- 완성된 공간 효과: 에너지 구체, 방어막, 번개 등
- DocC와 GitHub Pages 배포 자동화

## 문서 목록

- [01. Hand Jutsu 시작하기](./01-hand-jutsu-overview.md)
- [02. 첫 Immersive Space](./02-creating-immersive-space.md)
- [03. 양손 Hand Tracking 시작하기](./03-starting-hand-tracking.md)
- [04. 관절을 공간에 그리기](./04-joint-visualization.md)
- [05. Pose Features로 이어가기](./05-building-pose-features.md)

## 기기별 확인 원칙

- Simulator와 Apple Vision Pro에서 가능한 동작을 구분한다.
- 실제 Hand Anchor가 필요한 절차는 Apple Vision Pro에서 안내한다.
- 합성 좌표 테스트와 실제 손 입력에서 관찰할 내용을 구분한다.
