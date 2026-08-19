# Hand Tracking × Pose Features 실기기 검증 앱

Apple Vision Pro에서 두 Spike를 실제 ARKit 입력으로 함께 확인하는 독립 Xcode 프로젝트입니다.

- [Issue #23](https://github.com/im-siu/2026TechMap_tutorial/issues/23): 통합 실기기 검증과 증거 수집
- [Hand Tracking PR #8](https://github.com/im-siu/2026TechMap_tutorial/pull/8): 권한, HandAnchor, 27개 관절, 월드 좌표 변환
- [Pose Features PR #7](https://github.com/im-siu/2026TechMap_tutorial/pull/7): 25개 관절 입력, 한 손·손가락·양손 특징 계산

Pose 분류 임계값, smoothing, 히스테리시스와 술법 효과는 범위에 포함하지 않습니다. 이번 기록을 보고 다음 단계의 정책을 정합니다.

## 실행과 기록 순서

1. `HandTrackingDeviceCheck.xcodeproj`를 Xcode에서 엽니다.
2. `HandTrackingDeviceCheck` 타깃의 **Signing & Capabilities**에서 Team을 확인합니다.
3. 서명 충돌이 나면 Bundle Identifier를 본인에게 고유한 값으로 바꿉니다.
4. Mac과 페어링한 Apple Vision Pro를 실행 대상으로 선택하고 Run합니다.
5. **실기기 검증 시작**을 누르고 손 추적 권한을 허용합니다.
6. 관절 구체와 좌우 `27 / 27`, Feature 입력 `25 / 25`를 확인합니다.
7. 영상 증거가 필요하면 Xcode의 Reality Composer Pro Developer Capture 또는 기기 화면 녹화를 먼저 시작합니다.
8. 앱에서 **검증 기록 시작**을 누릅니다. Immersive HUD의 `REC`, 세션 ID와 타이머가 영상에 들어가는지 확인합니다.
9. 자세를 바꿀 때 `NEUTRAL`, `OPEN`, `FIST`, `PINCH`, `OCCLUDE`, `RECOVER` 마커를 누르고 해당 자세를 3~5초 유지합니다.
10. **기록 종료** 뒤 **6개 파일 내보내기**로 AirDrop, Files 등을 선택합니다.
11. 영상 파일 이름에 앱의 세션 ID(`HT-...`)를 넣고 `DEVICE_TEST_LOG.md`를 작성합니다.

## 꼭 검증할 항목

### Hand Tracking

- 권한 허용 뒤 세션이 계속 실행되고 양손 Anchor update가 들어오는가
- 왼손 파란색, 오른손 분홍색 27개 관절 구체가 실제 손과 맞게 따라오는가
- `originFromAnchorTransform * anchorFromJointTransform` 결과가 이동·회전 중에도 시각적으로 맞는가
- 손을 가리거나 시야 밖으로 뺐을 때 `isTracked`, 관절 수, 손실 횟수가 예상대로 변하는가
- 손이 다시 보이면 관절과 특징 계산이 복구되는가
- 가만히 둔 손에서 좌표·거리·법선·직진도가 어느 정도 흔들리는가

### Pose Features

- 27개 ARKit 관절 중 forearm 2개를 제외한 25개가 정확히 같은 이름으로 연결되는가
- 일부 `Joint.isTracked == false`일 때 25개 완전 입력 정책 때문에 `missingJoints`가 얼마나 자주 발생하는가
- 펼친 손→부분 굽힘→주먹에서 손가락 `straightness`와 굽힘각이 일관된 방향으로 변하는가
- 핀치에서 엄지–검지 절대거리와 정규화 거리가 함께 감소하는가
- 손을 카메라에 가깝게/멀게 하거나 사용자가 바뀌어도 정규화값이 절대거리보다 안정적인가
- 손바닥 앞·뒤와 좌우 손에서 palm normal 방향이 의도와 맞는가
- 두 손의 중심 거리, 방향, 법선 정렬, 상호 마주봄 점수가 실제 자세와 맞는가
- 좌우 Anchor timestamp 차이가 어느 범위이며 양손 특징에 허용할 상한을 정할 수 있는가

## 단위: 모든 값이 cm인 것은 아님

ARKit transform의 translation과 PoseFeatures의 원본 거리 단위는 **미터(m)** 입니다. 앱 화면은 사람이 빨리 읽을 수 있도록 거리와 관절 좌표를 **센티미터(cm)** 로 바꿔 보여주지만, 기록 파일은 정밀도를 유지하기 위해 m로 저장합니다.

| 값 | 화면 | 파일 | 의미 |
| --- | --- | --- | --- |
| 관절 X/Y/Z, 손바닥 중심, 거리 | cm(일부 손목 행은 m 병기) | m | ARKit 월드 공간 또는 두 점 사이 거리 |
| normalized 값, straightness | 소수 | 무단위 | 손 크기 비율 또는 길이 비율 |
| palm normal, 방향 벡터 | 소수 | 무단위 단위 벡터 | 방향 |
| 굽힘각 | degree(°) | radian(rad) | 인접 뼈 벡터 사이 각도 |
| Anchor timestamp / skew | ms로 일부 표시 | second(s) | ARKit 시각과 좌우 시각 차이 |

따라서 “모든 관절값이 cm”라는 표현은 화면 표시에는 맞지만 데이터 계약에는 맞지 않습니다. CSV 열 이름의 `_m`, `_s`, `_radians`가 저장 단위를 명시합니다.

## 기록 파일

기록은 앱 Documents의 `HandTrackingVerifications/<session-id>/`에 생성되고 종료 후 Share Sheet로 내보냅니다.

| 파일 | 용도 |
| --- | --- |
| `anchors.ndjson` | 매 수신 Anchor update의 원본 구조, 27개 관절과 그 순간의 전체 PoseFeatures |
| `joints.csv` | 분석하기 쉬운 관절별 long-format; update마다 27행, `joint_tracked`, `x_m/y_m/z_m` 포함 |
| `features.csv` | 좌우 손바닥·다섯 손가락·양손 특징, 오류와 누락 관절, timestamp skew |
| `markers.csv` | 영상과 맞추는 마커 번호·이름·기록 시작 이후 경과 시간 |
| `metadata.json` | 기기/OS/앱/SDK, 스키마 버전, 두 Spike 기준 commit, 단위 |
| `summary.json` | 시간·update 수·추적/비추적 행·특징 성공/실패·손실·마커 집계 |

손 전체가 추적되지 않아 skeleton 좌표가 없는 update도 `joints.csv`에 27행을 남깁니다. 이때 `joint_tracked=false`이고 좌표 칸은 비어 있습니다. 추적되지 않은 관절을 임의의 `(0, 0, 0)`으로 대체하지 않습니다.

## 영상과 수치 맞추기

영상 프레임 자체와 ARKit timestamp를 자동으로 같은 media container에 mux하지는 않습니다. 대신 아래 세 가지 동기화 단서를 영상과 파일에 동시에 남깁니다.

- HUD의 고유 세션 ID
- 기록 시작 기준 0.1초 타이머
- 사용자가 누르는 번호 있는 자세 마커

예를 들어 영상에서 `#4 PINCH`가 보이면 `markers.csv`의 4번 행 `elapsed_wall_s`를 찾고, 같은 시간대의 `joints.csv`와 `features.csv`를 확인합니다. 프레임 단위 정밀 동기화가 필요해지면 이번 로그의 오차를 먼저 측정한 뒤 AVFoundation 기반 카메라/화면 캡처 결합을 별도 Issue로 진행합니다.

## 성공 기준

- generic build와 PoseFeatures 단위 테스트를 통과한다.
- 실기기에서 권한·Anchor·27개 관절 시각화가 동작한다.
- 완전한 손에서는 각 손 Feature 입력이 `25 / 25`이고 추출이 성공한다.
- 가림 중 오류와 누락 관절이 기록되고 복구 뒤 다시 성공한다.
- 기록 종료 후 6개 파일이 열리며 session ID와 update 수가 서로 맞는다.
- 영상의 세션 ID·타이머·마커를 CSV의 동일 항목과 대응할 수 있다.
- 두 사람이 같은 시나리오를 수행해 정규화 후보와 오류율을 비교할 수 있다.

## 환경 메모

프로젝트 생성 시점(2026-08-19)의 로컬 도구는 Xcode 26.6, visionOS SDK 26.5입니다. Deployment Target은 visionOS 2.0입니다. 생성 시점에는 Apple Vision Pro가 연결되어 있지 않아 generic visionOS/Simulator 빌드와 합성 좌표 테스트까지만 자동 확인하며, 실제 권한·좌표 정합성·노이즈는 이 문서의 절차로 실기기에서 확인해야 합니다.
