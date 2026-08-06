# Spatial Jutsu Tutorial

SwiftUI, RealityKit, ARKit으로 Apple Vision Pro의 양손 Hand Pose를 인식하고 공간 술법 효과를 만드는 DocC 기초 튜토리얼 프로젝트입니다.

> 현재 단계: 프로젝트 방향과 기술 가능성을 확인하는 초기 탐색 단계

## 협업을 시작하기 전에

### 사람이 읽을 문서

1. [`TEAM_COLLABORATION_GUIDE.md`](TEAM_COLLABORATION_GUIDE.md) — 두 팀원의 전체 협업 방식과 Git 컨벤션
2. [`docs/PROJECT_FOUNDATION.md`](docs/PROJECT_FOUNDATION.md) — 현재 프로젝트 원칙, 학습 여정, 기술 기준과 미결정 사항

### AI가 읽을 문서

1. [`AGENTS.md`](AGENTS.md) — AI 작업 범위, 구현 원칙과 검증 규칙
2. [`docs/PROJECT_FOUNDATION.md`](docs/PROJECT_FOUNDATION.md) — 합의된 프로젝트 맥락과 아직 확정하지 않은 사항

## 허허벌판에서 시작하는 순서

```text
Genesis Issue
→ 두 사람의 독립적인 AI 탐색
→ 상호 반박과 공식 자료 확인
→ PROJECT_FOUNDATION.md 합의
→ Hand Tracking·Pose·DocC Pages 기술 Spike
→ 튜토리얼 목차 확정
→ 장 단위 Issue와 PR
```

1. 통합 Issue 템플릿으로 `[DISCOVERY] 프로젝트 Genesis`를 만듭니다.
2. 두 팀원이 각자의 AI로 대상 독자, 학습 결과, 범위와 위험을 독립적으로 제안합니다.
3. 서로의 제안을 개선하기 전에 반례, 누락과 검증할 가정을 찾습니다.
4. 합의한 내용만 `docs/PROJECT_FOUNDATION.md`에 반영하는 첫 PR을 만듭니다.
5. 불확실한 기술은 완성 앱보다 작은 `[SPIKE]` Issue로 먼저 검증합니다.
6. Spike 결과를 바탕으로 `[TUTORIAL]` Issue를 장 단위로 만듭니다.

## GitHub 템플릿

- [통합 Issue 템플릿](.github/ISSUE_TEMPLATE/project-work.md) — 탐색, 결정, Spike, 구현, 검증과 오류에 공통 사용
- [Pull Request 템플릿](.github/pull_request_template.md) — 작업 결과, 주요 코드, 화면, AI 활용과 검증 기록

Issue 제목의 태그는 다음 중 하나를 사용합니다.

```text
[DISCOVERY] [DECISION] [SPIKE] [TUTORIAL] [VERIFY] [FIX]
```

구현과 문서 작업은 Issue에서 범위와 완료 조건을 합의한 뒤 시작합니다. AI 답변은 제안으로 취급하고, 공식 자료·빌드·Simulator·실기기 결과로 확인한 내용만 프로젝트 기준으로 반영합니다.
