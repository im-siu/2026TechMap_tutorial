# 05. Pose Features로 이어가기

이전: [4장 관절을 공간에 그리기](./04-joint-visualization.md)

## 이 장의 목표

이 장에서는 Hand Tracking에서 만든 관절 좌표가 Pose Features 계산으로 어떻게 이어지는지 정리한다.

관절 입력을 받는 부분과 특징을 계산하는 부분을 분리하면, 각 역할을 더 작고 명확하게 다룰 수 있다.

## 연결 흐름 요약

튜토리얼은 다음 흐름으로 설명한다.

```text
HandAnchor
→ HandTrackingSnapshot
→ HandJointSample.originFromJointTransform
→ SIMD3<Float> position
→ Pose Features 입력
→ 손 모양 판정 재료
```

`HandTrackingService`는 ARKit의 `HandAnchor`를 직접 다룬다. Pose Features 계산은 ARKit과 RealityKit에 직접 의존하지 않고, `SIMD3<Float>` 위치 값을 입력으로 받도록 분리한다.

이렇게 분리하면 손 추적 입력과 Pose Features 계산을 각각 이해하고 확인할 수 있다.

## Pose Features 입력 재료

Hand Tracking 단계는 다음 정보를 Pose Features 단계로 넘긴다.

- 왼손/오른손 구분
- 손 전체 추적 상태
- 관절 이름
- 관절별 추적 여부
- 관절별 월드 transform

Pose Features 쪽에서는 `originFromJointTransform.columns.3`에서 위치 값을 꺼내 `SIMD3<Float>` 입력으로 사용할 수 있다.

## 포즈별 입력 정책

포즈마다 필요한 관절은 다르다. 손바닥 크기, 손가락 사이 거리, 손가락 굽힘, 손목-손끝 거리를 계산할 때도 해당 특징에 필요한 관절만 입력으로 사용한다.

- 포즈에 필요한 관절 중 하나라도 빠진 프레임은 `missingJoints`로 보고 특징 계산을 건너뛴다.
- 누락 관절을 영점 좌표로 채우지 않는다.

## 왜 영점 좌표로 채우지 않는가

추적되지 않은 관절을 `(0, 0, 0)` 같은 임의 좌표로 대체하면 계산은 계속될 수 있지만, 결과는 실제 손 모양과 무관한 값이 된다.

예를 들어 손끝 관절 하나가 누락되었는데 영점 좌표로 대체하면 다음 값들이 모두 왜곡될 수 있다.

- 손목-손끝 거리
- 손가락 직진도
- 손가락 굽힘 각도
- 손바닥 크기 정규화 값
- 양손 사이 거리와 방향

그래서 이 튜토리얼은 "없는 데이터를 만들어서 판정하지 않는다"는 원칙을 사용한다.

## 입력 누락을 다루는 원칙

> 추적되지 않은 관절을 영점 좌표로 대체하지 않으며, 포즈에 필요한 관절이 누락된 프레임의 특징 계산을 건너뛴다.

## Apple Vision Pro에서 살펴볼 항목

- 실제 손에서 25개 필수 관절이 동시에 확보되는 비율
- 손 가림과 빠른 움직임에서 관절별 추적 손실 빈도
- 실제 월드 좌표의 방향, 단위, 좌우 손 법선 보정 결과
- 실제 손 크기 차이에 대한 정규화 안정성
- 술, 인, 축 포즈별 특징값 범위와 판정 임계값
- smoothing, 히스테리시스, 자세 유지 시간의 필요성

## 다음 구현으로 이어갈 작업

다음 단계에서는 이 흐름을 앱 안에서 연결한다.

그때는 다음을 다룬다.

- `HandTrackingSnapshot`을 Pose Features 입력 타입으로 변환하는 어댑터 위치
- 포즈별로 필요한 관절을 어떻게 정의할지
- UI에서 특징값과 누락 관절을 어떻게 표시할지

## 이 장의 완료 기준

- Hand Tracking 출력이 Pose Features 입력으로 어떻게 변환되는지 설명할 수 있다.
- 누락 관절을 임의 좌표로 채우지 않는 이유를 설명할 수 있다.
- Apple Vision Pro에서 조정할 값을 설명할 수 있다.

이전: [4장 관절을 공간에 그리기](./04-joint-visualization.md)
