# Hand Tracking × Pose Features 실기기 검증 기록

## 환경과 증거

- 앱 기록 세션 ID (`HT-...`):
- 날짜/시간:
- 검증자:
- Xcode:
- Apple Vision Pro / visionOS:
- 앱 commit:
- 화면 녹화 파일 또는 링크:
- 내보낸 로그 폴더 또는 링크:

## 시나리오 결과

| 마커 | 수행 방법 | 결과 | 영상 시각 / `elapsed_wall_s` | 관찰 |
| --- | --- | --- | --- | --- |
| START | 기록 직후 양손 정면 | 미실행 | | |
| NEUTRAL | 편한 중립 자세 5초 | 미실행 | | |
| OPEN | 손가락을 펴고 5초 | 미실행 | | |
| FIST | 주먹을 쥐고 5초 | 미실행 | | |
| PINCH | 엄지–검지 접촉 5초 | 미실행 | | |
| OCCLUDE | 한 손을 가리거나 시야 밖으로 이동 | 미실행 | | |
| RECOVER | 손을 다시 보이고 5초 | 미실행 | | |

## 통합 체크리스트

| 확인 항목 | 결과 | 관찰 내용 |
| --- | --- | --- |
| Vision Pro에서 앱 설치·실행 | 미실행 | |
| 권한 허용 후 HandTrackingProvider 실행 | 미실행 | |
| 왼손 파랑 / 오른손 분홍 관절 표시 | 미실행 | |
| 양손 최대 27개 관절과 실제 손 정합 | 미실행 | |
| PoseFeatures 각 손 25개 입력 성공 | 미실행 | |
| 펼침→주먹에서 직진도 감소·굽힘각 증가 | 미실행 | |
| 핀치에서 엄지–검지 거리 감소 | 미실행 | |
| 손바닥 법선 방향이 앞·뒤 및 좌우에서 기대와 일치 | 미실행 | |
| 양손 거리·방향·마주봄 값이 실제 자세와 일치 | 미실행 | |
| 가림 중 추적 손실·missingJoints 기록 | 미실행 | |
| 가림 해제 후 관절과 Feature 복구 | 미실행 | |
| 영상의 세션 ID·타이머·마커와 CSV 대응 | 미실행 | |
| 6개 파일 열기와 session ID 일치 | 미실행 | |

## 로그 요약

`summary.json`에서 옮깁니다.

| 항목 | 값 |
| --- | ---: |
| durationSeconds | |
| anchorUpdateCount | |
| leftUpdateCount / rightUpdateCount | |
| trackedJointRowCount / untrackedJointRowCount | |
| left feature 성공 / 실패 | |
| right feature 성공 / 실패 | |
| bimanual feature 성공 / 실패 | |
| left / right tracking loss | |
| markerCount | |

## 핵심 수치 비교

각 구간의 중앙값과 흔들림 범위 또는 min/max를 `features.csv`에서 적습니다. 임계값은 이 단계에서 확정하지 않습니다.

| 특징 | NEUTRAL | OPEN | FIST | PINCH | 메모 |
| --- | ---: | ---: | ---: | ---: | --- |
| index straightness | | | | | |
| middle straightness | | | | | |
| normalized index tip–wrist | | | | | |
| normalized thumb–index | | | | | |
| palm width (m) | | | | | |
| palm length (m) | | | | | |
| geometric mean (m) | | | | | |
| hand timestamp skew (s) | | | | | |

## 결론과 후속 결정

- 성공/실패:
- 25개 완전 관절 정책을 유지할 수 있는가:
- 정규화 기준 후보(너비/길이/기하평균) 중 가장 안정적인 값:
- 양손 timestamp skew 허용 상한 후보:
- 프레임 smoothing 또는 히스테리시스가 필요한 특징:
- 재현 절차와 예상 밖 동작:
- 후속 Issue:
