# Pink Swirl Fish Tutorial

SwiftUI, RealityKit, ARKit으로 Apple Vision Pro의 양손 Hand Pose를 인식하고 공간 술법 효과를 만드는 DocC 기초 튜토리얼 프로젝트입니다.

> 현재 단계: 프로젝트 방향과 기술 가능성을 확인하는 초기 탐색 단계

## 협업 기준

- 사람은 [GitHub Wiki](https://github.com/im-siu/2026TechMap_tutorial/wiki)에서 팀 운영 방식과 탐색 기록을 먼저 읽습니다.
- 프로젝트의 공식 기준은 PR 리뷰가 가능한 [`docs/PROJECT_FOUNDATION.md`](docs/PROJECT_FOUNDATION.md)에서 관리합니다.
- AI는 [`AGENTS.md`](AGENTS.md), 프로젝트 기초 문서와 연결된 Issue를 읽습니다.

## GitHub 템플릿

- [방향 탐색](.github/ISSUE_TEMPLATE/discovery.md) — 대상 독자, 문제와 가능한 방향
- [설계 결정](.github/ISSUE_TEMPLATE/decision.md) — 선택지 비교와 팀 기준 확정
- [기술 Spike](.github/ISSUE_TEMPLATE/spike.md) — 불확실한 기술의 최소 실험
- [튜토리얼 작업](.github/ISSUE_TEMPLATE/tutorial.md) — 앱 코드와 DocC 제작
- [검증 기록](.github/ISSUE_TEMPLATE/verify.md) — API, 빌드, 실기기와 배포 확인
- [오류 수정](.github/ISSUE_TEMPLATE/fix.md) — 재현 가능한 문제 해결
- [탐색·결정·Spike PR](.github/PULL_REQUEST_TEMPLATE/exploration.md) — 질문, 근거와 결론
- [구현·수정 PR](.github/PULL_REQUEST_TEMPLATE/implementation.md) — 코드, DocC, 화면과 검증
- [검증·CI PR](.github/PULL_REQUEST_TEMPLATE/verification.md) — 환경, 절차, 결과와 후속 작업

Issue 제목의 태그는 다음 중 하나를 사용합니다.

```text
[DISCOVERY] [DECISION] [SPIKE] [TUTORIAL] [VERIFY] [FIX]
```

구현과 문서 작업은 Issue에서 범위와 완료 조건을 합의한 뒤 시작합니다. AI 답변은 제안으로 취급하고, 공식 자료·빌드·Simulator·실기기 결과로 확인한 내용만 프로젝트 기준으로 반영합니다.
