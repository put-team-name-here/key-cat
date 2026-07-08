import SwiftUI

/// 오버레이 창 내용. 그래픽은 전부 회색/단색 박스 플레이스홀더.
struct OverlayView: View {
    @ObservedObject var counter: KeyCounter
    @ObservedObject var state: AppState
    var onToggleSize: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))

            VStack(spacing: 12) {
                // 고양이 캐릭터 자리 (회색 박스)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.85))
                    .frame(width: 90, height: 65)
                    .overlay(
                        Text("고양이\n캐릭터")
                            .font(.system(size: 11))
                            .multilineTextAlignment(.center)
                    )

                infoRow(label: "오늘 타자 수", value: "\(counter.count)")

                Text(statusMessage)
                    .font(.system(size: 11))
                    .foregroundColor(counter.permissionGranted ? .secondary : .red)
                    .multilineTextAlignment(.center)

                // 확장 시 나타나는 농장 영역 (초록 박스)
                if state.expanded {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.41, green: 0.73, blue: 0.46))
                        .overlay(Text("농장 영역").font(.title3).foregroundColor(.white))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer(minLength: 0)
            }
            .padding(16)

            // 축소/확장 버튼
            Button(action: onToggleSize) {
                Image(systemName: state.expanded
                    ? "arrow.down.right.and.arrow.up.left"
                    : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .padding(12)
        }
    }

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
