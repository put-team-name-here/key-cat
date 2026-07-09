import SwiftUI

/// 오버레이 창 내용. 그래픽은 전부 회색/단색 박스 플레이스홀더.
/// 축소(작은 위젯) / 확장(농장 패널) 두 화면을 state.expanded 로 전환.
struct OverlayView: View {
    @ObservedObject var counter: KeyCounter
    @ObservedObject var state: AppState
    var onToggleSize: () -> Void

    // 플레이스홀더 색
    private let farmGreen = Color(red: 0.55, green: 0.73, blue: 0.52)
    private let boxGray = Color(white: 0.85)
    private let panelWhite = Color.white

    var body: some View {
        Group {
            if state.expanded {
                expandedView
            } else {
                collapsedView
            }
        }
    }

    // MARK: - 축소 화면 (작은 위젯)

    private var collapsedView: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))

            VStack(spacing: 12) {
                // 고양이 캐릭터 자리 (회색 박스)
                RoundedRectangle(cornerRadius: 8)
                    .fill(boxGray)
                    .frame(width: 90, height: 65)
                    .overlay(Text("고양이\n캐릭터")
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center))

                infoRow(label: "오늘 타자 수", value: "\(counter.count)")

                Text(statusMessage)
                    .font(.system(size: 11))
                    .foregroundColor(counter.permissionGranted ? .secondary : .red)
                    .multilineTextAlignment(.center)

                Spacer(minLength: 0)
            }
            .padding(16)

            // 확장 버튼
            Button(action: onToggleSize) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .padding(12)
        }
    }

    // MARK: - 확장 화면 (농장 패널)

    private var expandedView: some View {
        VStack(spacing: 0) {
            farmArea
            currencyRow
            shopPreview
            bottomTabs
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(panelWhite))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // 상단 초록 농장 영역: 말풍선 + 고양이 + 잔디블록 밭 그리드
    private var farmArea: some View {
        ZStack(alignment: .topTrailing) {
            farmGreen

            // 우상단 버튼들 (화면 축소 / 설정)
            HStack(spacing: 8) {
                circleButton(title: "화면\n축소\n버튼", action: onToggleSize)
                circleButton(title: "설정\n버튼", action: {})
            }
            .padding(12)

            VStack(alignment: .leading, spacing: 16) {
                // 말풍선 + 캐릭터가 말 거는 자리
                HStack(alignment: .top, spacing: 6) {
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(boxGray)
                            .frame(width: 150, height: 120)
                        VStack(spacing: 6) {
                            Text("김혜지")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.55, green: 0.4, blue: 0.85))
                                .cornerRadius(6)
                            Text("고양이 집\n지어주나요?")
                                .font(.system(size: 12))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 12)
                    }
                    Image(systemName: "cursorarrow")
                        .foregroundColor(Color(red: 0.55, green: 0.4, blue: 0.85))
                        .padding(.top, 30)
                }
                .padding(.leading, 20)

                // 고양이 (돌아다님)
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("고양이\n(돌아다님)")
                            .font(.system(size: 11))
                            .multilineTextAlignment(.center)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(boxGray)
                            .frame(width: 34, height: 46)
                    }
                    .padding(.trailing, 24)
                }

                // 잔디블록 라벨 + 3x3 밭 그리드
                HStack(alignment: .center, spacing: 10) {
                    Text("잔디\n블록")
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                    farmGrid
                    Spacer()
                }
                .padding(.leading, 16)

                Spacer(minLength: 0)
            }
            .padding(.top, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // 3x3 밭 그리드 (씨앗/성장중/성장완료/수확 표시 라벨)
    private var farmGrid: some View {
        let labels: [[String]] = [
            ["밭", "", ""],
            ["", "", ""],
            ["", "", ""],
            ["씨앗", "성장중", "성장완료"]
        ]
        return ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                ForEach(0..<labels.count, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { c in
                            Rectangle()
                                .fill(boxGray)
                                .border(Color.black.opacity(0.4), width: 0.5)
                                .frame(width: 56, height: 42)
                                .overlay(Text(labels[r][c]).font(.system(size: 11)))
                        }
                    }
                }
            }
            // 수확 가능 표시
            Text("수확 가능 표시")
                .font(.system(size: 9))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(boxGray)
                .cornerRadius(8)
                .offset(x: 60, y: -6)
        }
    }

    // 현재 타자 수 / 보유 재화 행
    private var currencyRow: some View {
        HStack(spacing: 10) {
            labeledBox(label: "현재 타자 수", value: "\(counter.count)")
            labeledBox(label: "보유 재화", value: "")
        }
        .padding(12)
        .background(panelWhite)
    }

    // 상점 미리보기 (당근/양배추 + 나머지 아직 없음)
    private var shopPreview: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                shopItem(name: "당근")
                shopItem(name: "양배추")
                emptyItem
                emptyItem
            }
            ZStack {
                HStack(spacing: 12) {
                    emptyItem
                    emptyItem
                    emptyItem
                    emptyItem
                }
                Text("나머지는 대충 아직 없다 표시")
                    .font(.system(size: 15, weight: .semibold))
            }
        }
        .padding(12)
        .background(panelWhite)
    }

    // 하단 탭 (버튼만, 동작 없음)
    private var bottomTabs: some View {
        HStack(spacing: 0) {
            ForEach(["상점", "창고", "도감", "기록"], id: \.self) { title in
                Button(action: {}) {
                    Text(title)
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .overlay(Rectangle().stroke(Color.black.opacity(0.3), lineWidth: 0.5))
            }
        }
        .background(panelWhite)
    }

    // MARK: - 조각 뷰

    private func circleButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9))
                .multilineTextAlignment(.center)
                .frame(width: 40, height: 40)
                .background(boxGray)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func labeledBox(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12))
            Spacer()
            Text(value).font(.system(size: 13, weight: .bold)).monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.3), lineWidth: 0.5))
    }

    private func shopItem(name: String) -> some View {
        VStack(spacing: 4) {
            Text("\(name)\n그림").font(.system(size: 11)).multilineTextAlignment(.center)
            Text("가격").font(.system(size: 11))
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(boxGray)
        .cornerRadius(4)
    }

    private var emptyItem: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(boxGray)
            .frame(maxWidth: .infinity, minHeight: 60)
    }

    // MARK: - 공용

    private var statusMessage: String {
        if !counter.permissionGranted {
            return "⚠️ 입력 모니터링 권한 필요\n(시스템 설정에서 허용 후 자동 연결)"
        }
        return counter.count == 0 ? "아무 앱에서나 타이핑해 보세요" : "실시간 카운트 중"
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12))
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(white: 0.92))
        .cornerRadius(6)
    }
}
