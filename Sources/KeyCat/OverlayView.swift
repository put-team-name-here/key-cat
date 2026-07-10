import SwiftUI
import AppKit

/// GUI PNG asset cache for small overlay status icons.
enum GuiAssetCache {
    private static var cache: [String: NSImage] = [:]

    static func image(_ name: String) -> NSImage? {
        if let img = cache[name] { return img }
        guard let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "gui"),
              let img = NSImage(contentsOf: url) else { return nil }
        cache[name] = img
        return img
    }
}

/// 오버레이 창 내용. stt-spike RHODES 콘솔 테마 이식.
/// 축소(작은 위젯) / 확장(농장 콘솔) 두 화면을 state.expanded 로 전환.
struct OverlayView: View {
    @ObservedObject var counter: KeyCounter
    @ObservedObject var state: AppState
    var onToggleSize: () -> Void
    /// "설정" 버튼: 메뉴바 NSMenu 를 popUp (AppDelegate 배선)
    var onOpenSettings: () -> Void = {}

    private let t = Theme.rhodes
    private let rt = RetroTheme.shared

    var body: some View {
        Group {
            if state.expanded {
                expandedView
            } else {
                collapsedView
            }
        }
    }

    // MARK: - 축소 화면 (레트로 픽셀 카드, 시안 축소화면.dc.html)

    /// 카드 하드 그림자(5px5px). 투명 패널 안에서 그림자용 여백을 확보한다.
    private var collapsedView: some View {
        HStack(alignment: .top, spacing: 14) {
            catColumn
            statsColumn
        }
        .padding(14)
        .frame(width: 352, alignment: .topLeading)
        .background(rt.cardBg)
        .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.28))
                .offset(x: 5, y: 5)
        )
        .padding(.trailing, 5)
        .padding(.bottom, 5)
        .fixedSize()
    }

    // MARK: 좌측 - 고양이 박스 + "변경" 버튼

    private var catColumn: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                GrassBackground()
                WalkingCat(character: state.selectedCat, spriteSize: 46, fps: 9)
            }
            .frame(width: 118, height: 118)
            .clipped()
            .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))

            Button(action: state.cycleCat) {
                Text("변경")
                    .font(galmuriFont(12))
                    .foregroundColor(rt.ink)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(rt.yellow))
                    .overlay(Circle().strokeBorder(rt.ink, lineWidth: 3))
                    .shadow(color: Color.black.opacity(0.25), radius: 0, x: 2, y: 2)
            }
            .buttonStyle(.plain)
            .offset(x: 10, y: 10)
        }
        .frame(width: 118, height: 118, alignment: .topLeading)
    }

    // MARK: 우측 - 상단 버튼행 + 정보 타일 3종

    private var statsColumn: some View {
        VStack(spacing: 7) {
            // 확장 아이콘 + 설정 버튼
            HStack(spacing: 6) {
                Spacer(minLength: 0)
                Button(action: onToggleSize) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(rt.ink)
                        .frame(width: 15, height: 15)
                        .padding(.horizontal, 7)
                        .frame(maxHeight: .infinity)
                        .background(rt.panel)
                        .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
                }
                .buttonStyle(.plain)

                Button(action: onOpenSettings) {
                    Text("설정")
                        .font(galmuriFont(13))
                        .foregroundColor(rt.text)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(rt.panel)
                        .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
                }
                .buttonStyle(.plain)
            }
            .fixedSize(horizontal: false, vertical: true)

            // 기록한 글자 수
            infoTile {
                keyboardGlyph
                Spacer(minLength: 0)
                Text("\(counter.count)자")
                    .font(galmuriFont(14)).foregroundColor(rt.text)
            }

            // 보유 코인
            infoTile {
                coinGlyph
                Spacer(minLength: 0)
                Text("\(state.coins)")
                    .font(galmuriFont(14)).foregroundColor(rt.text)
            }

            // 수확 상태
            infoTile {
                Rectangle()
                    .fill(state.harvestAvailable ? rt.harvestReady : rt.harvestWait)
                    .frame(width: 11, height: 11)
                    .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 2))
                Text(state.harvestAvailable ? "수확할 수 있어요!" : "아직 자라는 중")
                    .font(galmuriFont(13)).foregroundColor(rt.text)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// 정보 타일: panel 배경 + ink 3px 테두리 + 좌측 아이콘 행
    private func infoTile<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8, content: content)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(rt.panel)
            .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 3))
    }

    /// assets/gui/key_cap_2.png 기반 타자 수 아이콘. 리소스 누락 시 기존 픽셀 아이콘으로 폴백.
    @ViewBuilder private var keyboardGlyph: some View {
        if let img = GuiAssetCache.image("key_cap_2") {
            Image(nsImage: img)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 22, height: 22)
                .accessibilityLabel("타자 수")
        } else {
            legacyKeyboardGlyph
        }
    }

    /// assets/gui/coin_2.png 기반 보유 코인 아이콘. 리소스 누락 시 기존 픽셀 아이콘으로 폴백.
    @ViewBuilder private var coinGlyph: some View {
        if let img = GuiAssetCache.image("coin_2") {
            Image(nsImage: img)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 22, height: 22)
                .accessibilityLabel("보유 코인")
        } else {
            legacyCoinGlyph
        }
    }

    /// 폴백용 핑크 키보드 픽셀 아이콘 (20x18, 키 3개)
    private var legacyKeyboardGlyph: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(rt.pink)
            pixel(x: 3, y: 4, w: 4, h: 4, color: rt.pinkKey)
            pixel(x: 10, y: 4, w: 4, h: 4, color: rt.pinkKey)
            pixel(x: 3, y: 10, w: 11, h: 4, color: rt.pinkKey)
        }
        .frame(width: 20, height: 18)
        .overlay(Rectangle().strokeBorder(rt.ink, lineWidth: 2))
    }

    /// 폴백용 노란 코인 픽셀 아이콘 (18x18 원, 눈2 + 입)
    private var legacyCoinGlyph: some View {
        ZStack(alignment: .topLeading) {
            Circle().fill(rt.yellow)
            pixel(x: 4, y: 5, w: 3, h: 4, color: rt.ink)
            pixel(x: 10, y: 5, w: 3, h: 4, color: rt.ink)
            pixel(x: 6, y: 10, w: 6, h: 3, color: rt.ink)
        }
        .frame(width: 18, height: 18)
        .overlay(Circle().strokeBorder(rt.ink, lineWidth: 2))
    }

    /// topLeading 기준 오프셋 픽셀 사각형 (시안 절대좌표 재현)
    private func pixel(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: w, height: h)
            .offset(x: x, y: y)
    }

    // MARK: - 확장 화면 (농장 콘솔)

    private var expandedView: some View {
        VStack(spacing: 0) {
            expandedHeader
            Rectangle().fill(t.border).frame(height: 1)
            farmArea
            currencyRow
            shopPreview
            bottomTabs
        }
        .background(t.panel)
        .overlay(Rectangle().stroke(t.border, lineWidth: 1))
        .cornerBrackets([.tl, .br], color: t.accent)
    }

    private var expandedHeader: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                logoMark
                VStack(alignment: .leading, spacing: 2) {
                    Text("타이핑 농장")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(t.text)
                    Text("TYPING · FARM")
                        .font(monoFont(9))
                        .tracking(2)
                        .foregroundColor(t.textDim)
                }
                Spacer()
                iconButton(system: "arrow.down.right.and.arrow.up.left", action: onToggleSize)
                iconButton(system: "gearshape", action: {})
            }
            HStack {
                Text(t.brand)
                    .font(monoFont(9, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(t.accent)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(t.accentSoft)
                    .overlay(Rectangle().stroke(t.accent, lineWidth: 1))
                Spacer()
                Text("SESSION · #0428")
                    .font(monoFont(9))
                    .tracking(1)
                    .foregroundColor(t.textFaint)
            }
        }
        .padding(14)
    }

    // 초록 밭 필드: 말풍선 + 고양이 + 밭 그리드
    private var farmArea: some View {
        ZStack(alignment: .topTrailing) {
            t.field

            VStack(alignment: .leading, spacing: 16) {
                // 말풍선 + 캐릭터
                HStack(alignment: .top, spacing: 6) {
                    ZStack(alignment: .top) {
                        Rectangle()
                            .fill(t.fieldCell)
                            .frame(width: 150, height: 120)
                            .overlay(Rectangle().stroke(t.borderStrong, lineWidth: 1))
                        VStack(spacing: 6) {
                            Text("김혜지")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(t.accentText)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(t.accent)
                            Text("고양이 집\n지어주나요?")
                                .font(.system(size: 12))
                                .foregroundColor(t.text)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 12)
                    }
                    Image(systemName: "cursorarrow")
                        .foregroundColor(t.accent)
                        .padding(.top, 30)
                }
                .padding(.leading, 18)

                // 고양이 (돌아다님)
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("고양이\n(돌아다님)")
                            .font(.system(size: 11))
                            .foregroundColor(t.text)
                            .multilineTextAlignment(.center)
                        Rectangle()
                            .fill(t.fieldCell)
                            .frame(width: 34, height: 46)
                            .overlay(Rectangle().stroke(t.borderStrong, lineWidth: 1))
                    }
                    .padding(.trailing, 22)
                }

                // 잔디 블록 라벨 + 밭 그리드
                HStack(alignment: .center, spacing: 10) {
                    VStack(spacing: 2) {
                        Text("잔디\n블록")
                            .font(.system(size: 12))
                            .foregroundColor(t.text)
                            .multilineTextAlignment(.center)
                        Text("PLOT")
                            .font(monoFont(8)).tracking(1.5)
                            .foregroundColor(t.accent2)
                    }
                    farmGrid
                    Spacer()
                }
                .padding(.leading, 14)

                Spacer(minLength: 0)
            }
            .padding(.top, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

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
                                .fill(t.fieldCell)
                                .overlay(Rectangle().stroke(t.borderStrong, lineWidth: 1))
                                .frame(width: 56, height: 42)
                                .overlay(Text(labels[r][c])
                                    .font(.system(size: 11))
                                    .foregroundColor(t.text))
                        }
                    }
                }
            }
            // 수확 가능 표시
            Text("수확 가능")
                .font(monoFont(8, weight: .bold)).tracking(1)
                .foregroundColor(t.accent)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(t.panel)
                .overlay(Rectangle().stroke(t.accent, lineWidth: 1))
                .offset(x: 54, y: -8)
        }
    }

    // 현재 타자 수 / 보유 재화
    private var currencyRow: some View {
        HStack(spacing: 10) {
            statTile(ko: "현재 타자 수", en: "KEYS", value: "\(counter.count)")
            statTile(ko: "보유 재화", en: "CURRENCY", value: "0")
        }
        .padding(14)
    }

    // 상점 미리보기
    private var shopPreview: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                shopItem(name: "당근")
                shopItem(name: "양배추")
                emptyItem
                emptyItem
            }
            ZStack {
                HStack(spacing: 10) {
                    emptyItem; emptyItem; emptyItem; emptyItem
                }
                Text("나머지는 대충 아직 없다 표시")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(t.textDim)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    // 하단 탭 (번호 스텝 스타일, 동작 없음)
    private var bottomTabs: some View {
        let tabs = [("01", "상점", "SHOP"), ("02", "창고", "STORAGE"),
                    ("03", "도감", "CODEX"), ("04", "기록", "LOG")]
        return HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { i, tab in
                let active = i == 0
                VStack(spacing: 5) {
                    Text(tab.0)
                        .font(monoFont(11, weight: .bold))
                        .foregroundColor(active ? t.accentText : t.textDim)
                        .frame(width: 28, height: 28)
                        .background(active ? t.accent : Color.clear)
                        .overlay(CutCorner(tr: 6, bl: 6).stroke(active ? t.accent : t.border, lineWidth: 1))
                        .clipShape(CutCorner(tr: 6, bl: 6))
                    Text(tab.1)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(active ? t.accent : t.text)
                    Text(tab.2)
                        .font(monoFont(8)).tracking(1.5)
                        .foregroundColor(t.textFaint)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .overlay(Rectangle().stroke(t.border, lineWidth: 0.5))
            }
        }
        .background(t.panelAlt)
    }

    // MARK: - 조각 뷰

    /// 로고 마크: 러스트 사각 + 잘린 모서리
    private var logoMark: some View {
        ZStack {
            CutCorner(br: 10).fill(t.accent).frame(width: 32, height: 32)
            Rectangle().fill(t.accentText).frame(width: 11, height: 11)
        }
    }

    private func iconButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(t.accent2)
                .frame(width: 32, height: 32)
                .background(t.panelAlt)
                .overlay(Rectangle().stroke(t.borderStrong, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    /// 통계 타일 (모노 대문자 서브라벨 + 큰 모노 값)
    private func statTile(ko: String, en: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Text(en).font(monoFont(8, weight: .bold)).tracking(1.5)
                    .foregroundColor(t.textFaint)
                Text(ko).font(.system(size: 10))
                    .foregroundColor(t.textDim)
            }
            Text(value)
                .font(monoFont(20, weight: .bold))
                .foregroundColor(t.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(t.bg2)
        .overlay(Rectangle().stroke(t.border, lineWidth: 1))
    }

    private func shopItem(name: String) -> some View {
        VStack(spacing: 4) {
            Text(name).font(.system(size: 12, weight: .semibold)).foregroundColor(t.text)
            Text("가격").font(monoFont(9)).tracking(1).foregroundColor(t.textDim)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(t.bg2)
        .overlay(Rectangle().stroke(t.border, lineWidth: 1))
    }

    private var emptyItem: some View {
        Rectangle()
            .fill(t.bg2)
            .frame(maxWidth: .infinity, minHeight: 58)
            .overlay(Rectangle().stroke(t.border, lineWidth: 1))
    }
}
