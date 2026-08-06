# AI 작업 지침

이 파일은 이 저장소에서 작업하는 모든 AI 에이전트가 먼저 읽고 따라야 하는 공통 지침이다. 사람을 위한 전체 협업 방식은 `TEAM_COLLABORATION_GUIDE.md`에 있다.

## 프로젝트 목표

SwiftUI, RealityKit, ARKit을 이용해 Apple Vision Pro에서 양손 Hand Pose를 인식하고 공간 술법 효과를 구현하는 초급 DocC 튜토리얼과 실행 가능한 visionOS 예제 앱을 만든다. 완성된 DocC는 GitHub Pages로 정적 배포한다.

튜토리얼은 머신러닝 모델보다 `HandTrackingProvider`, `HandAnchor`, `HandSkeleton` 관절의 거리와 방향을 이용한 규칙 기반 인식을 우선한다. 화려한 효과보다 좌표 변환, 포즈 판정, 안정화, 상태 전환과 디버깅 과정을 학습자가 이해하는 것이 중요하다.

## 작업을 시작하기 전에

1. 이 파일 전체를 읽는다.
2. `TEAM_COLLABORATION_GUIDE.md`를 읽는다.
3. 사용자가 지정한 Issue와 관련 파일을 읽는다.
4. 작업 트리의 기존 변경을 확인하고 보존한다.
5. Issue에 목표, 범위, 제외 범위와 완료 조건이 있는지 확인한다.

Issue가 없다면 사용자가 요청한 범위만 처리한다. 큰 설계 변경, 새로운 의존성, 배포 방식 변경 또는 여러 튜토리얼 장에 걸친 작업을 임의로 확장하지 않는다.

## 신뢰할 정보의 우선순위

1. 현재 저장소에서 빌드와 테스트로 확인한 결과
2. Apple 또는 GitHub의 최신 공식 문서와 공식 샘플
3. 기본 브랜치의 코드, DocC와 결정 문서
4. 연결된 Issue와 PR의 합의
5. 블로그, 커뮤니티 글과 AI 답변

AI가 이전에 생성한 설명을 사실 근거로 재사용하지 않는다. 최신성에 영향을 받는 API, Xcode, visionOS, GitHub Actions와 Pages 정보는 공식 원문으로 다시 확인한다.

## 작업 범위와 안전

- 연결된 Issue의 완료 조건에 필요한 최소 변경만 한다.
- 관련 없는 리팩터링, 파일 이동, 이름 변경과 포맷 변경을 섞지 않는다.
- 사용자의 기존 변경을 덮어쓰거나 되돌리지 않는다.
- 파괴적인 Git 명령을 사용하지 않는다.
- 비밀 값, 인증 정보, 개인정보, DerivedData와 사용자별 Xcode 상태 파일을 커밋하지 않는다.
- 새 패키지나 외부 의존성을 추가하기 전에 필요성과 대안을 설명하고 사람의 결정을 받는다.
- 컴파일이나 실기기 테스트를 하지 않았다면 했다고 표현하지 않는다.

## 구현 원칙

가능하면 다음 책임을 분리한다.

```text
HandTrackingService
- ARKitSession과 HandTrackingProvider 생명주기
- 왼손과 오른손 HandAnchor 수집

HandPose 또는 HandFeatures
- 관절의 월드 좌표와 파생 특징

GestureClassifier
- 펼친 손, 주먹, 핀치와 양손 관계 판정

SpellStateMachine
- idle, preparing, charging, releasing, cooldown 전환

SpellEffectController
- RealityKit Entity와 시각 효과 관리
```

초급 단계에서 파일 수를 줄일 이유가 있으면 일부를 합칠 수 있지만, 손 인식 규칙이 RealityKit 효과를 직접 생성하게 만들지 않는다.

### ARKit와 손 추적

- `HandTrackingProvider.isSupported`를 확인한다.
- 권한 거부, 세션 오류, 취소와 추적 손실을 정상 상태로 처리한다.
- `HandAnchor.isTracked`와 `handSkeleton` 부재 가능성을 처리한다.
- 관절의 월드 변환은 좌표계와 행렬 곱 순서를 공식 문서와 대조한다.
- 양손 Anchor가 서로 다른 시점에 갱신될 수 있음을 고려한다.
- 손 크기에 민감한 절대 거리에는 의미와 한계를 주석과 DocC에 적는다.
- 포즈 경계 깜빡임에는 유지 시간, smoothing 또는 서로 다른 진입·해제 임계값을 검토한다.
- 실기기에서 자연스러운 손 가림이 발생하므로 모든 관절의 `isTracked`를 무조건 요구하지 않는다.

### Swift와 SwiftUI

- UI와 RealityKit Entity 변경의 actor 격리를 명확히 한다.
- 장시간 실행되는 `Task`는 소유자, 취소 시점과 재시작 동작을 정의한다.
- `ImmersiveSpace` 열기 결과와 시스템에 의한 닫힘을 상태에 반영한다.
- 고빈도 관절 업데이트마다 불필요하게 전체 SwiftUI View를 갱신하지 않는다.
- 오류를 `print`로만 버리지 말고 학습자가 이해할 상태 또는 설명을 제공한다.

### RealityKit

- Entity는 매 프레임 새로 만들지 말고 생성과 갱신을 분리한다.
- 위치가 월드 좌표인지 부모 기준 좌표인지 명시한다.
- 공간 효과는 구체, 선, 평면, 파티클처럼 학습 목적에 맞게 구분한다.
- `SimpleMaterial`의 metallic과 실제 발광 효과를 혼동하지 않는다.
- Particle preset 색상과 구체 재질 색상이 자동으로 일치한다고 가정하지 않는다.
- 빠른 움직임과 추적 해제 시 남는 Entity 또는 파티클을 확인한다.

## DocC 작성 규칙

- 각 장은 학습 목표, 예상 결과, 단계, 코드 설명, 확인 방법과 오류 해결을 포함한다.
- 한 장에서 새 핵심 개념을 과도하게 늘리지 않는다.
- 관절 시각화와 디버깅 단계를 포즈 판정보다 먼저 소개한다.
- 코드 조각은 실제 앱 코드와 컴파일 가능한 상태를 기준으로 한다.
- `Resources/CodeListings`를 별도로 사용한다면 앱 코드 변경 시 함께 확인한다.
- 코드 리스팅이 특정 학습 단계의 중간 상태라면 파일과 본문에서 이를 명시한다.
- API 설명에는 가능한 한 Apple 공식 문서를 연결한다.
- 임계값은 보편적인 정답이 아니라 조정 가능한 예제 시작값으로 설명한다.
- Simulator에서 가능한 검증과 Apple Vision Pro가 필요한 검증을 구분한다.
- 지원 Xcode와 visionOS 버전은 추정하지 말고 프로젝트 설정 또는 합의 문서에서 확인한다.

권장 학습 순서는 다음과 같다.

```text
프로젝트와 권한
→ ImmersiveSpace
→ 양손 Anchor 수집
→ 관절 시각화와 좌표 변환
→ 한 손 특징 추출
→ 양손 포즈 판정
→ 흔들림과 오인식 보정
→ RealityKit 효과
→ 상태 머신과 동적 술법
→ 실기기 테스트
→ DocC와 GitHub Pages 배포
```

## Git과 협업 규칙

- Issue 하나의 목적에 집중한다.
- 브랜치와 커밋 규칙은 `TEAM_COLLABORATION_GUIDE.md`를 따른다.
- 요청받지 않은 커밋, push, merge 또는 PR 생성은 하지 않는다.
- PR 설명에는 `Closes #번호`, AI 활용 범위, 검증 결과와 미검증 항목을 남긴다.
- 중요한 설계 선택은 코드만으로 암묵적으로 결정하지 말고 `설계 결정` Issue의 합의를 요구한다.
- 두 AI의 답변이 충돌하면 한 답을 임의로 선택하지 말고 공식 자료나 최소 재현으로 비교한다.

## 검증 규칙

변경 위험에 비례해 가능한 검증을 수행한다.

### Swift 또는 프로젝트 변경

- 현재 프로젝트와 scheme을 확인한다.
- 지원 Xcode에서 관련 target을 빌드한다.
- 동시성 경고와 권한 설명을 확인한다.
- 실기기 전용 동작은 코드 검증과 기기 검증을 구분해 보고한다.

### DocC 변경

- `Product > Build Documentation` 또는 동일한 `xcodebuild docbuild`를 수행한다.
- 깨진 `doc:` 링크, 리소스 이름과 코드 리스팅을 확인한다.
- 가능하면 생성된 문서의 주요 페이지를 시각적으로 확인한다.

### GitHub Pages 변경

- `DOCC_HOSTING_BASE_PATH`가 저장소 유형과 맞는지 확인한다.
- Action 버전과 runner의 Xcode/visionOS SDK 가용성을 공식 자료와 실행 로그로 확인한다.
- 루트, 하위 문서 URL, 이미지, CSS, 직접 URL 접근과 새로고침을 확인한다.

검증을 실행할 수 없다면 실패가 아니라 제한 사항으로 명확히 보고하고, 사람이 수행할 정확한 절차를 남긴다.

## 작업 완료 보고 형식

AI는 완료 시 다음을 짧고 구체적으로 보고한다.

```text
결과
- 학습자 또는 프로젝트 관점에서 달라진 점

변경 파일
- 파일과 역할

검증
- 실제 수행한 검증과 결과

남은 확인
- 실기기, 버전 또는 사람이 결정해야 할 항목
```

“완료했다”는 표현은 Issue의 필수 완료 조건을 충족했을 때만 사용한다.
