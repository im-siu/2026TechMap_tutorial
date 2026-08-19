import SwiftUI

struct DashboardView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @State private var isShowingCustomMarker = false
    @State private var customMarkerText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                sessionCard

                HStack(spacing: 12) {
                    handCard(side: .left, observation: service.metrics.left)
                    handCard(side: .right, observation: service.metrics.right)
                }

                recordingCard
                liveMeasurementsCard
                fingerFeaturesCard
                jointCoordinatesCard
                controls
                logCard
            }
            .padding(28)
        }
        .frame(width: 760, height: 760)
        .sheet(isPresented: $isShowingCustomMarker) {
            customMarkerSheet
        }
    }

    private var service: HandTrackingService {
        appModel.handTracking
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hand Tracking × Pose Features 실기기 검증")
                .font(.largeTitle.bold())
            Text("Issue #23 · Hand Tracking PR #8 · Pose Features PR #7")
                .foregroundStyle(.secondary)
        }
    }

    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: statusSymbol)
                    .foregroundStyle(statusColor)
                Text(service.status.title)
                    .font(.title2.bold())
                Spacer()
                Text(service.isSupported ? "지원됨" : "지원 확인 필요")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(service.isSupported ? .green : .orange)
            }

            Text(service.status.detail)
                .foregroundStyle(.secondary)

            Divider()
            LabeledContent("손 추적 권한", value: service.authorization.rawValue)
            LabeledContent("마지막 수신", value: lastUpdateText)

            if let error = appModel.immersiveSpaceError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
        .padding(20)
        .glassBackgroundEffect()
    }

    private func handCard(side: HandSide, observation: HandObservation) -> some View {
        let feature = side == .left ? service.poseFeatures.left : service.poseFeatures.right

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(side == .left ? .blue : .pink)
                    .frame(width: 12, height: 12)
                Text(side.title)
                    .font(.headline)
                Spacer()
                Text(observation.isTracked ? "추적 중" : "미추적")
                    .foregroundStyle(observation.isTracked ? .green : .secondary)
            }
            LabeledContent("ARKit 관절", value: "\(observation.jointCount) / 27")
            LabeledContent("Feature 입력", value: "\(feature.sampleJointCount) / 25")
            LabeledContent("수신률", value: String(format: "%.1f Hz", observation.updateRateHz))
            LabeledContent("업데이트", value: "\(observation.updateCount)")
            LabeledContent("손실", value: "\(observation.lossCount)")
            LabeledContent("특징 추출", value: feature.isSuccess ? "성공" : "실패")
                .foregroundStyle(feature.isSuccess ? .green : .orange)
            if let error = feature.errorCode {
                Text(error)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.orange)
                    .textSelection(.enabled)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .glassBackgroundEffect()
    }

    private var recordingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(
                    service.recordingState.title,
                    systemImage: service.recordingState.isRecording ? "record.circle.fill" : "record.circle"
                )
                .font(.headline)
                .foregroundStyle(service.recordingState.isRecording ? .red : .primary)
                Spacer()
                if service.recordingState.isRecording {
                    TimelineView(.periodic(from: .now, by: 0.1)) { context in
                        Text(elapsed(service.recordingElapsed(at: context.date)))
                            .monospacedDigit()
                            .font(.headline)
                    }
                }
            }

            LabeledContent("세션 ID", value: service.recordingSessionID ?? "—")
                .font(.callout.monospaced())
                .textSelection(.enabled)
            LabeledContent("저장된 Anchor update", value: "\(service.recordedAnchorUpdateCount)")

            if case .failed(let message) = service.recordingState {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 10) {
                if service.hasActiveRecording {
                    Button(role: .destructive) {
                        service.stopRecording()
                    } label: {
                        Label(
                            service.recordingState.isRecording ? "기록 종료" : "오류 기록 정리",
                            systemImage: "stop.fill"
                        )
                    }
                } else {
                    Button {
                        service.startRecording()
                    } label: {
                        Label("수치 기록 시작", systemImage: "record.circle")
                    }
                    .disabled(!service.canStartRecording)
                }

                if !service.exportURLs.isEmpty {
                    ShareLink(items: service.exportURLs) {
                        Label("6개 파일 내보내기", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            Text("이 버튼은 관절·특징 수치만 기록합니다. 화면과 실제 손 영상은 자동 녹화되지 않으므로 기기 화면 녹화 또는 Developer Capture를 별도로 시작하세요.")
                .font(.caption)
                .foregroundStyle(.orange)

            Text("검증 대상 수인 3개")
                .font(.subheadline.bold())

            Text("손동작을 시작하는 순간 누르면 이름과 시간이 CSV 및 Immersive HUD에 함께 남습니다.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 140), spacing: 8)],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(NinjutsuHandSeal.allCases) { seal in
                    Button(seal.displayName) {
                        service.addHandSealMarker(seal)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!service.recordingState.isRecording)
                }

                Button {
                    customMarkerText = ""
                    isShowingCustomMarker = true
                } label: {
                    Label("기타", systemImage: "square.and.pencil")
                }
                .buttonStyle(.bordered)
                .disabled(!service.recordingState.isRecording)
            }

        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackgroundEffect()
    }

    private var customMarkerSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("기타 손동작 기록")
                .font(.title2.bold())
            Text("현재 수행하는 손동작을 알아볼 수 있게 적어 주세요. 입력한 문장은 영상 HUD와 내보낸 markers.csv에 저장됩니다.")
                .foregroundStyle(.secondary)

            TextField(
                "예: 오른손 검지·중지를 펴고 왼손은 주먹",
                text: $customMarkerText,
                axis: .vertical
            )
            .lineLimit(3...6)
            .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("취소", role: .cancel) {
                    isShowingCustomMarker = false
                }
                Button("기타 마커 저장") {
                    service.addCustomMarker(customMarkerText)
                    isShowingCustomMarker = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(customMarkerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(28)
        .frame(width: 560, height: 300)
    }

    private var liveMeasurementsCard: some View {
        let left = service.poseFeatures.left
        let right = service.poseFeatures.right
        let both = service.poseFeatures.bimanual

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Pose Features 실시간 수치")
                    .font(.headline)
                Spacer()
                Text("화면 약 4회/초 · 파일은 매 update")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 9) {
                GridRow {
                    Text("측정값").foregroundStyle(.secondary)
                    Text("왼손").foregroundStyle(.blue)
                    Text("오른손").foregroundStyle(.pink)
                }
                Divider()
                measurementRow("손목 월드 X / Y / Z", left: positionText(service.metrics.left.wristWorldPosition), right: positionText(service.metrics.right.wristWorldPosition))
                measurementRow("손바닥 너비", left: centimeters(left.palmWidthMeters), right: centimeters(right.palmWidthMeters))
                measurementRow("손바닥 길이", left: centimeters(left.palmLengthMeters), right: centimeters(right.palmLengthMeters))
                measurementRow("정규화 기준 √(너비×길이)", left: centimeters(left.geometricMeanMeters), right: centimeters(right.geometricMeanMeters))
                measurementRow("엄지–검지 끝", left: centimeters(left.thumbIndexTipDistanceMeters), right: centimeters(right.thumbIndexTipDistanceMeters))
                measurementRow("정규화 핀치", left: ratio(left.normalizedThumbIndexTipDistance), right: ratio(right.normalizedThumbIndexTipDistance))
                measurementRow("손바닥 법선 X / Y / Z", left: vectorText(left.palmNormal), right: vectorText(right.palmNormal))
                GridRow {
                    Text("양손 손바닥 중심 거리")
                    Text(centimeters(both.palmCenterDistanceMeters)).monospacedDigit().gridCellColumns(2)
                }
                GridRow {
                    Text("정규화 양손 거리")
                    Text(ratio(both.normalizedPalmCenterDistance)).monospacedDigit().gridCellColumns(2)
                }
                GridRow {
                    Text("왼쪽→오른쪽 방향")
                    Text(vectorText(both.leftToRightDirection)).monospacedDigit().gridCellColumns(2)
                }
                GridRow {
                    Text("법선 정렬 / 상호 마주봄")
                    Text("\(number(both.palmNormalAlignment)) / \(number(both.mutualFacingScore))")
                        .monospacedDigit().gridCellColumns(2)
                }
                GridRow {
                    Text("좌우 timestamp 차이")
                    Text(milliseconds(both.timestampSkewSeconds)).monospacedDigit().gridCellColumns(2)
                }
            }
            .font(.callout)

            Text("ARKit 좌표와 거리의 원본/저장 단위는 m입니다. 화면만 cm로 변환하며, 정규화값·법선·방향은 무단위, 굽힘각은 파일에서 rad입니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackgroundEffect()
    }

    private var fingerFeaturesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("손가락별 특징")
                .font(.headline)
            Text("straightness 1에 가까울수록 곧음 · 굽힘각은 화면에서 °, CSV에서는 rad")
                .font(.caption)
                .foregroundStyle(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                GridRow {
                    Text("손 / 손가락").foregroundStyle(.secondary)
                    Text("곧음").foregroundStyle(.secondary)
                    Text("손목–끝 / 정규화").foregroundStyle(.secondary)
                    Text("굽힘각들").foregroundStyle(.secondary)
                }
                ForEach(HandSide.allCases, id: \.self) { side in
                    let hand = side == .left ? service.poseFeatures.left : service.poseFeatures.right
                    ForEach(["thumb", "index", "middle", "ring", "little"], id: \.self) { finger in
                        let feature = hand.fingers[finger]
                        GridRow {
                            Text("\(side == .left ? "L" : "R") · \(finger)")
                                .foregroundStyle(side == .left ? .blue : .pink)
                            Text(number(feature?.straightness)).monospacedDigit()
                            Text("\(centimeters(feature?.tipToWristDistanceMeters)) / \(ratio(feature?.normalizedTipToWristDistance))")
                                .monospacedDigit()
                            Text(degrees(feature?.bendAnglesRadians)).monospacedDigit()
                        }
                    }
                }
            }
            .font(.caption)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackgroundEffect()
    }

    private var jointCoordinatesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("27개 ARKit 관절 월드 좌표")
                .font(.headline)
            Text("화면 표시: cm · joints.csv 저장: m · forearmArm/forearmWrist는 PoseFeatures 25개 입력에서 제외")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(HandSide.allCases, id: \.self) { side in
                DisclosureGroup("\(side.title) 관절 펼치기") {
                    Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
                        GridRow {
                            Text("관절").foregroundStyle(.secondary)
                            Text("tracked").foregroundStyle(.secondary)
                            Text("X / Y / Z (cm)").foregroundStyle(.secondary)
                        }
                        ForEach(joints(for: side), id: \.name) { joint in
                            GridRow {
                                Text(HandJointCatalog.stableName(for: joint.name)).monospaced()
                                Image(systemName: joint.isTracked ? "checkmark.circle.fill" : "xmark.circle")
                                    .foregroundStyle(joint.isTracked ? .green : .secondary)
                                Text(positionCentimeters(joint.worldPosition)).monospacedDigit()
                            }
                        }
                    }
                    .font(.caption)
                    .padding(.top, 8)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackgroundEffect()
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                toggleImmersiveSpace()
            } label: {
                Label(
                    appModel.immersiveSpaceState == .open ? "검증 중지" : "실기기 검증 시작",
                    systemImage: appModel.immersiveSpaceState == .open ? "stop.fill" : "play.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(appModel.immersiveSpaceState == .inTransition)

            Button("관찰값 초기화") {
                service.resetObservations()
            }
            .buttonStyle(.bordered)

            ShareLink(item: service.reportText) {
                Label("요약 공유", systemImage: "doc.text")
            }
            .buttonStyle(.bordered)
        }
    }

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 이벤트")
                .font(.headline)

            if service.logEntries.isEmpty {
                Text("아직 기록된 이벤트가 없습니다.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(service.logEntries.prefix(8)) { entry in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(entry.timestamp, format: .dateTime.hour().minute().second())
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Text(entry.message)
                    }
                    .font(.callout)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackgroundEffect()
    }

    private func joints(for side: HandSide) -> [HandJointSample] {
        service.displaySnapshot[side]?.joints ?? []
    }

    private func measurementRow(_ label: String, left: String, right: String) -> some View {
        GridRow {
            Text(label)
            Text(left).monospacedDigit()
            Text(right).monospacedDigit()
        }
    }

    private func positionText(_ position: SIMD3<Float>?) -> String {
        guard let position else { return "—" }
        return String(format: "%.3f / %.3f / %.3f m", position.x, position.y, position.z)
    }

    private func positionCentimeters(_ position: SIMD3<Float>) -> String {
        String(format: "%.2f / %.2f / %.2f", position.x * 100, position.y * 100, position.z * 100)
    }

    private func vectorText(_ vector: SIMD3<Float>?) -> String {
        guard let vector else { return "—" }
        return String(format: "%.3f / %.3f / %.3f", vector.x, vector.y, vector.z)
    }

    private func centimeters(_ meters: Float?) -> String {
        guard let meters else { return "—" }
        return String(format: "%.2f cm", meters * 100)
    }

    private func ratio(_ value: Float?) -> String {
        guard let value else { return "—" }
        return String(format: "%.3f", value)
    }

    private func number(_ value: Float?) -> String {
        guard let value else { return "—" }
        return String(format: "%.3f", value)
    }

    private func milliseconds(_ seconds: TimeInterval?) -> String {
        guard let seconds else { return "—" }
        return String(format: "%.1f ms", seconds * 1_000)
    }

    private func degrees(_ radians: [Float]?) -> String {
        guard let radians else { return "—" }
        return radians.map { String(format: "%.1f°", $0 * 180 / .pi) }.joined(separator: " / ")
    }

    private func elapsed(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainder = seconds - Double(minutes * 60)
        return String(format: "%02d:%04.1f", minutes, remainder)
    }

    private var lastUpdateText: String {
        service.metrics.lastUpdateAt?.formatted(date: .omitted, time: .standard) ?? "없음"
    }

    private var statusSymbol: String {
        if service.status.isFailure { return "xmark.octagon.fill" }
        if service.status == .running { return "checkmark.circle.fill" }
        return "circle.dotted"
    }

    private var statusColor: Color {
        if service.status.isFailure { return .red }
        if service.status == .running { return .green }
        return .orange
    }

    private func toggleImmersiveSpace() {
        Task { @MainActor in
            appModel.immersiveSpaceError = nil

            switch appModel.immersiveSpaceState {
            case .open:
                appModel.immersiveSpaceState = .inTransition
                await dismissImmersiveSpace()

            case .closed:
                appModel.immersiveSpaceState = .inTransition
                switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                case .opened:
                    break
                case .userCancelled:
                    appModel.immersiveSpaceState = .closed
                    appModel.immersiveSpaceError = "Immersive Space 열기를 취소했습니다."
                case .error:
                    appModel.immersiveSpaceState = .closed
                    appModel.immersiveSpaceError = "Immersive Space를 열지 못했습니다."
                @unknown default:
                    appModel.immersiveSpaceState = .closed
                    appModel.immersiveSpaceError = "알 수 없는 Immersive Space 응답입니다."
                }

            case .inTransition:
                break
            }
        }
    }
}
